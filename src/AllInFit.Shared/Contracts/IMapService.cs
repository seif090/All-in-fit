namespace AllInFit.Shared.Contracts;

/// <summary>
/// Abstraction for map services using OpenStreetMap, Nominatim, OSRM, and Overpass API.
/// No Google Maps dependency.
/// </summary>
public interface IMapService
{
    Task<LocationResult> GetCurrentLocationAsync(CancellationToken cancellationToken = default);
    Task<AddressResult> ReverseGeocodeAsync(double latitude, double longitude, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<PlaceResult>> SearchNearbyAsync(SearchNearbyRequest request, CancellationToken cancellationToken = default);
    Task<DistanceResult> CalculateDistanceAsync(Coordinate origin, Coordinate destination, CancellationToken cancellationToken = default);
    Task<DurationResult> GetEtaAsync(Coordinate origin, Coordinate destination, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<Coordinate>> GetRouteAsync(Coordinate origin, Coordinate destination, CancellationToken cancellationToken = default);
}

public record Coordinate(double Latitude, double Longitude);

public record LocationResult(bool Success, double? Latitude, double? Longitude, string? Error);

public record AddressResult(
    bool Success,
    string? DisplayName,
    string? Street,
    string? City,
    string? State,
    string? Country,
    string? PostalCode,
    string? Error);

public record PlaceResult(
    string Id,
    string Name,
    string? Category,
    double Latitude,
    double Longitude,
    string? Address,
    string? Phone,
    string? Website,
    double? DistanceInMeters,
    double? Rating);

public record SearchNearbyRequest(
    double Latitude,
    double Longitude,
    double RadiusInMeters = 1000,
    string? Category = null,
    string? SearchTerm = null,
    int Limit = 20);

public record DistanceResult(
    bool Success,
    double? DistanceInMeters,
    double? DistanceInKilometers,
    string? Error);

public record DurationResult(
    bool Success,
    double? DurationInSeconds,
    string? DurationText,
    string? Error);

public enum NearbyCategory
{
    Gym,
    Doctor,
    Pharmacy,
    Restaurant,
    SupplementStore,
    All
}
