# API Documentation

Current production-backed endpoints:

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/forgot-password`
- `POST /api/v1/auth/reset-password`
- `POST /api/v1/auth/verify-email`
- `GET /api/v1/users/me`
- `GET /api/v1/users/{userId}`
- `GET /api/v1/gyms/{gymId}`
- `POST /api/v1/gyms`
- `PUT /api/v1/gyms/{gymId}`
- `DELETE /api/v1/gyms/{gymId}`
- `GET /health`
- `GET /swagger/v1/swagger.json`

## Notes

- The API uses versioned routes under `api/v1`.
- Swagger is enabled in Development and Testing environments.
- A Postman collection is available at `docs/AllInFit.postman_collection.json`.
- Error responses use a consistent `success=false` envelope from the controller base and middleware.