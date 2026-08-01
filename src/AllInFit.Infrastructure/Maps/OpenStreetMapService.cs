using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using AllInFit.Shared.Contracts;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace AllInFit.Infrastructure.Maps;

/// <summary>
/// Map service built on open-source geography stack:
/// Nominatim (geocoding/reverse geocoding), OSRM (routing/distance/ETA), Overpass API (nearby POI search).
/// No Google Maps dependency.
/// </summary>
public sealed class OpenStreetMapService : IMapService
{
    private readonly MapServiceOptions _options;
    private readonly ILogger<OpenStreetMapService> _logger;
    private readonly HttpClient _http;

    public OpenStreetMapService(IOptions<MapServiceOptions> options, ILogger<OpenStreetMapService> logger, IHttpClientFactory httpFactory)
    {
        _options = options.Value;
        _logger = logger;
        _http = httpFactory.CreateClient("MapService");
        _http.DefaultRequestHeaders.UserAgent.ParseAdd(_options.UserAgent);
        if (!string.IsNullOrWhiteSpace(_options.Email))
            _http.DefaultRequestHeaders.Add("email", _options.Email);
    }

    public Task<LocationResult> GetCurrentLocationAsync(CancellationToken cancellationToken = default)
    {
        // IP-based geolocation is not included by design (privacy). Clients provide coordinates explicitly.
        return Task.FromResult(new LocationResult(false, null, null, "Geolocation requires client-provided coordinates"));
    }

    public async Task<AddressResult> ReverseGeocodeAsync(double latitude, double longitude, CancellationToken cancellationToken = default)
    {
        try
        {
            var url = $"{_options.NominatimBaseUrl}/reverse?format=jsonv2&lat={latitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)}&lon={longitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)}&addressdetails=1&zoom=18";

            var response = await _http.GetAsync(url, cancellationToken);
            response.EnsureSuccessStatusCode();

            var result = await response.Content.ReadFromJsonAsync<NominatimReverseResponse>(cancellationToken: cancellationToken);
            if (result is null)
                return new AddressResult(false, null, null, null, null, null, null, "No address found");

            var address = result.Address;
            return new AddressResult(
                true,
                result.DisplayName,
                address?.Road,
                address?.City ?? address?.Town ?? address?.Village,
                address?.State,
                address?.Country,
                address?.Postcode,
                null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Reverse geocoding failed for {Lat},{Lng}", latitude, longitude);
            return new AddressResult(false, null, null, null, null, null, null, ex.Message);
        }
    }

    public async Task<IReadOnlyList<PlaceResult>> SearchNearbyAsync(SearchNearbyRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var radius = Math.Min(request.RadiusInMeters, _options.MaxRadiusInMeters);
            var categoryQuery = OsmCategoryMapper.GetOverpassQuery(request.Category);

            // Overpass QL: center around coordinate, query within radius
            var queryBuilder = new StringBuilder();
            queryBuilder.Append("[out:json][timeout:25];(");
            queryBuilder.Append(categoryQuery);
            queryBuilder.Append(");out center;");

            using var content = new FormUrlEncodedContent(new Dictionary<string, string> { ["data"] = queryBuilder.ToString() });
            var response = await _http.PostAsync(_options.OverpassBaseUrl, content, cancellationToken);
            response.EnsureSuccessStatusCode();

            var json = await response.Content.ReadFromJsonAsync<OverpassResponse>(cancellationToken: cancellationToken);
            if (json?.Elements is null)
                return Array.Empty<PlaceResult>();

            var places = new List<PlaceResult>();
            foreach (var element in json.Elements.Take(request.Limit))
            {
                var lat = element.Lat ?? element.Center?.Lat;
                var lon = element.Lon ?? element.Center?.Lon;
                if (lat is null || lon is null) continue;

                var distance = HaversineDistance(request.Latitude, request.Longitude, lat.Value, lon.Value);
                if (distance > radius) continue;

                var tags = element.Tags;
                var name = tags?.GetValueOrDefault("name") ?? tags?.GetValueOrDefault("brand") ?? (tags?.GetValueOrDefault("amenity") ?? tags?.GetValueOrDefault("shop") ?? "Point of interest");

                places.Add(new PlaceResult(
                    element.Id.ToString(),
                    name,
                    tags?.GetValueOrDefault("amenity") ?? tags?.GetValueOrDefault("shop") ?? tags?.GetValueOrDefault("leisure"),
                    lat.Value,
                    lon.Value,
                    tags?.GetValueOrDefault("addr:street"),
                    tags?.GetValueOrDefault("phone"),
                    tags?.GetValueOrDefault("website"),
                    distance,
                    null));
            }

            return places;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Nearby search failed at {Lat},{Lng}", request.Latitude, request.Longitude);
            return Array.Empty<PlaceResult>();
        }
    }

    public async Task<DistanceResult> CalculateDistanceAsync(Coordinate origin, Coordinate destination, CancellationToken cancellationToken = default)
    {
        try
        {
            var url = $"{_options.OSRMBaseUrl}/route/v1/driving/{origin.Longitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)},{origin.Latitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)};{destination.Longitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)},{destination.Latitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)}?overview=full&geometries=geojson";

            var response = await _http.GetAsync(url, cancellationToken);
            response.EnsureSuccessStatusCode();
            var result = await response.Content.ReadFromJsonAsync<OsrmRouteResponse>(cancellationToken: cancellationToken);

            if (result?.Routes is null || result.Routes.Count == 0)
                return new DistanceResult(false, null, null, "No route found");

            var route = result.Routes[0];
            return new DistanceResult(true, route.Distance, Math.Round(route.Distance / 1000, 2), null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Distance calculation failed");
            return new DistanceResult(false, null, null, ex.Message);
        }
    }

    public async Task<DurationResult> GetEtaAsync(Coordinate origin, Coordinate destination, CancellationToken cancellationToken = default)
    {
        try
        {
            var url = $"{_options.OSRMBaseUrl}/route/v1/driving/{origin.Longitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)},{origin.Latitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)};{destination.Longitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)},{destination.Latitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)}?overview=false";

            var response = await _http.GetAsync(url, cancellationToken);
            response.EnsureSuccessStatusCode();
            var result = await response.Content.ReadFromJsonAsync<OsrmRouteResponse>(cancellationToken: cancellationToken);

            if (result?.Routes is null || result.Routes.Count == 0)
                return new DurationResult(false, null, null, "No route found");

            var route = result.Routes[0];
            return new DurationResult(true, route.Duration, FormatDuration(route.Duration), null);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "ETA calculation failed");
            return new DurationResult(false, null, null, ex.Message);
        }
    }

    public async Task<IReadOnlyList<Coordinate>> GetRouteAsync(Coordinate origin, Coordinate destination, CancellationToken cancellationToken = default)
    {
        try
        {
            var url = $"{_options.OSRMBaseUrl}/route/v1/driving/{origin.Longitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)},{origin.Latitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)};{destination.Longitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)},{destination.Latitude.ToString("F6", System.Globalization.CultureInfo.InvariantCulture)}?overview=full&geometries=geojson";

            var response = await _http.GetAsync(url, cancellationToken);
            response.EnsureSuccessStatusCode();
            var result = await response.Content.ReadFromJsonAsync<OsrmRouteResponse>(cancellationToken: cancellationToken);

            if (result?.Routes is null || result.Routes.Count == 0)
                return Array.Empty<Coordinate>();

            var pointOptions = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            var coordinates = result.Routes[0].Geometry.Coordinates
                .Select(c => new Coordinate(c[1], c[0]))
                .ToList();

            return coordinates;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Route generation failed");
            return Array.Empty<Coordinate>();
        }
    }

    private static double HaversineDistance(double lat1, double lon1, double lat2, double lon2)
    {
        const double r = 6371000;
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return r * c;
    }

    private static double ToRadians(double degrees) => degrees * Math.PI / 180;

    private static string FormatDuration(double seconds)
    {
        var ts = TimeSpan.FromSeconds(seconds);
        return ts.TotalHours >= 1
            ? $"{(int)ts.TotalHours}h {ts.Minutes}m"
            : $"{ts.Minutes}m {ts.Seconds}s";
    }

    private sealed class NominatimReverseResponse
    {
        [JsonPropertyName("display_name")] public string? DisplayName { get; set; }
        [JsonPropertyName("address")] public NominatimAddress? Address { get; set; }
    }

    private sealed class NominatimAddress
    {
        [JsonPropertyName("road")] public string? Road { get; set; }
        [JsonPropertyName("city")] public string? City { get; set; }
        [JsonPropertyName("town")] public string? Town { get; set; }
        [JsonPropertyName("village")] public string? Village { get; set; }
        [JsonPropertyName("state")] public string? State { get; set; }
        [JsonPropertyName("country")] public string? Country { get; set; }
        [JsonPropertyName("postcode")] public string? Postcode { get; set; }
    }

    private sealed class OverpassResponse
    {
        [JsonPropertyName("elements")] public List<OverpassElement>? Elements { get; set; }
    }

    private sealed class OverpassElement
    {
        [JsonPropertyName("id")] public long Id { get; set; }
        [JsonPropertyName("lat")] public double? Lat { get; set; }
        [JsonPropertyName("lon")] public double? Lon { get; set; }
        [JsonPropertyName("center")] public OverpassCenter? Center { get; set; }
        [JsonPropertyName("tags")] public Dictionary<string, string>? Tags { get; set; }
    }

    private sealed class OverpassCenter
    {
        [JsonPropertyName("lat")] public double? Lat { get; set; }
        [JsonPropertyName("lon")] public double? Lon { get; set; }
    }

    private sealed class OsrmRouteResponse
    {
        [JsonPropertyName("routes")] public List<OsrmRoute>? Routes { get; set; }
    }

    private sealed class OsrmRoute
    {
        [JsonPropertyName("distance")] public double Distance { get; set; }
        [JsonPropertyName("duration")] public double Duration { get; set; }
        [JsonPropertyName("geometry")] public OsrmGeometry Geometry { get; set; } = new();
    }

    private sealed class OsrmGeometry
    {
        [JsonPropertyName("coordinates")] public List<List<double>> Coordinates { get; set; } = new();
    }
}