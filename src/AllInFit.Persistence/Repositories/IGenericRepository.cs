using AllInFit.Application.Ports;
using AllInFit.Domain.Specifications;

namespace AllInFit.Persistence.Repositories;

public interface IGenericRepository<T> : Application.Ports.IGenericRepository<T> where T : class
{
}