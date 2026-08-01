using AllInFit.Shared.Contracts;

namespace AllInFit.Infrastructure.Maps;

/// <summary>
/// Maps <see cref="NearbyCategory"/> and free-form categories to OpenStreetMap tags (Overpass QL).
/// </summary>
public static class OsmCategoryMapper
{
    private static readonly IReadOnlyDictionary<string, string> OverpassQuery = new Dictionary<string, string>
    {
        [NearbyCategory.Gym.ToString()] = "node[\"leisure\"=\"fitness_centre\"];node[\"leisure\"=\"sports_centre\"];way[\"leisure\"=\"fitness_centre\"];",
        [NearbyCategory.Doctor.ToString()] = "node[\"amenity\"=\"doctors\"];node[\"healthcare\"=\"doctor\"];way[\"amenity\"=\"doctors\"];",
        [NearbyCategory.Pharmacy.ToString()] = "node[\"amenity\"=\"pharmacy\"];way[\"amenity\"=\"pharmacy\"];",
        [NearbyCategory.Restaurant.ToString()] = "node[\"amenity\"=\"restaurant\"];way[\"amenity\"=\"restaurant\"];",
        [NearbyCategory.SupplementStore.ToString()] = "node[\"shop\"=\"health_food\"];node[\"shop\"=\"nutrition_supplements\"];way[\"shop\"=\"health_food\"];",
        [NearbyCategory.All.ToString()] =
            "node[\"amenity\"~\"restaurant|pharmacy|doctors|cafe|gym\"];node[\"leisure\"=\"fitness_centre\"];node[\"shop\"=\"health_food\"];" +
            "way[\"amenity\"~\"restaurant|pharmacy|doctors|cafe|gym\"];way[\"leisure\"=\"fitness_centre\"];"
    };

    public static string GetOverpassQuery(NearbyCategory category)
        => OverpassQuery.GetValueOrDefault(category.ToString(), OverpassQuery[NearbyCategory.All.ToString()]);

    public static string GetOverpassQuery(string? category)
    {
        if (string.IsNullOrWhiteSpace(category)) return GetOverpassQuery(NearbyCategory.All);
        if (Enum.TryParse<NearbyCategory>(category, true, out var parsed))
            return GetOverpassQuery(parsed);

        // Free-form category matching
        return $"node[\"{category}\"];way[\"{category}\"];";
    }
}