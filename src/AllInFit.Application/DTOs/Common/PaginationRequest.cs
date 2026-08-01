namespace AllInFit.Application.DTOs.Common;

public record PaginationRequest(int Page = 1, int PageSize = 10);
public record PagedResponse<T>(IReadOnlyList<T> Items, int Page, int PageSize, int TotalCount, int TotalPages);