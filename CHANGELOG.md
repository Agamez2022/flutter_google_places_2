# Changelog

## 2.0.0

- Migración completa del transporte a REST Places API (New); retirados modelos y endpoints Legacy.
- Nuevo PlacesClient compartido con Autocomplete/Query Predictions, Details, Nearby Search, Text Search y Photo Media; máscaras explícitas, sesiones e identidad móvil en todas las operaciones.
- API Dart incompatible: PlaceSelection contiene predicción y token; modelos camelCase y campos opcionales nullable.
- Widgets overlay/fullscreen con presentación conservada y doce referencias visuales anteriores a la migración.
- Correcciones de concurrencia de búsqueda, cursor Unicode, errores y propiedad/ciclo de vida de controladores.
- Guía de migración y ejemplo compilable. Pruebas locales sintéticas; comprobaciones reales de API, restricciones, geografía y plataformas pendientes antes de activar en una app.

## 1.0.0

Base del fork con Places Legacy.
