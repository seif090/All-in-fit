namespace AllInFit.Infrastructure.Maps;

public sealed class MapServiceOptions
{
    public const string SectionName = "Maps";

    public string NominatimBaseUrl { get; set; } = "https://nominatim.openstreetmap.org";
    public string OSRMBaseUrl { get; set; } = "https://router.project-osrm.org";
    public string OverpassBaseUrl { get; set; } = "https://overpass-api.de/api/interpreter";
    public string UserAgent { get; set; } = "AllInFit/1.0";
    public string Email { get; set; } = string.Empty;
    public int MaxRadiusInMeters { get; set; } = 5000;
}