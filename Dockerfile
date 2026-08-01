FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

COPY . .
RUN dotnet restore "src/AllInFit.Presentation/AllInFit.Presentation.csproj"
RUN dotnet publish "src/AllInFit.Presentation/AllInFit.Presentation.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS runtime
WORKDIR /app
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
EXPOSE 8080

RUN mkdir -p /app/logs /app/wwwroot/uploads

COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "AllInFit.Presentation.dll"]