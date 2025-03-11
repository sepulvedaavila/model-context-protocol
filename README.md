# Model Context Protocol System (MCPS)

MCPS is a comprehensive Elixir-based system designed to standardize, manage, and monitor contexts for AI/ML models.

## Overview

The MCPS provides a unified way to handle model contexts with four key components:

1. **Context Management Service**: Stores, retrieves, and versions model contexts
2. **Context Transformation Pipeline**: Processes and transforms contexts through configurable pipelines
3. **Protocol Gateway**: Provides standardized APIs for context operations
4. **Monitoring & Telemetry**: Tracks system performance and usage metrics

## Architecture

MCPS is built as an Elixir umbrella application with the following components:

- `mcps_core`: Core data structures and shared functionality
- `mcps_management`: Context storage, retrieval, and versioning
- `mcps_transform`: Transformation pipeline for context processing
- `mcps_telemetry`: Monitoring and metrics collection
- `mcps_gateway`: API gateway for external access
- `mcps_web`: Web interface and REST API

## Features

- **Context Management**
  - CRUD operations for contexts
  - Versioning and history tracking
  - Efficient caching for performance
  - Size validation and limits

- **Transformation Pipeline**
  - Configurable transformation steps
  - Extensible transformer architecture
  - Built-in transformers for common operations
  - Pipeline validation and error handling

- **API Gateway**
  - RESTful API with JSON responses
  - Authentication and authorization
  - Rate limiting and quotas
  - Swagger documentation

- **Monitoring & Telemetry**
  - Performance metrics collection
  - Operation tracking
  - Prometheus integration
  - Health checks

## Getting Started

### Prerequisites

- Elixir 1.14 or later
- Erlang/OTP 25 or later
- PostgreSQL 14 or later

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/mcps.git
   cd mcps
   ```

2. Install dependencies:
   ```bash
   mix deps.get
   ```

3. Create and migrate the database:
   ```bash
   mix ecto.create
   mix ecto.migrate
   ```

4. Start the application:
   ```bash
   mix phx.server
   ```

The API will be available at http://localhost:4000/api.
Swagger documentation is available at http://localhost:4000/api/swagger.

## API Documentation

### Authentication

The API supports two authentication methods:

1. **Bearer Token**: `Authorization: Bearer <token>`
2. **API Key**: `Authorization: ApiKey <key>`

### Endpoints

#### Contexts

- `GET /api/contexts` - List contexts
- `POST /api/contexts` - Create a context
- `GET /api/contexts/:id` - Get a context
- `PUT /api/contexts/:id` - Update a context
- `DELETE /api/contexts/:id` - Delete a context
- `GET /api/contexts/:id/versions` - List context versions
- `GET /api/contexts/:id/versions/:version` - Get a specific version

#### Pipelines

- `GET /api/pipelines` - List pipelines
- `POST /api/pipelines` - Create a pipeline
- `GET /api/pipelines/:id` - Get a pipeline
- `PUT /api/pipelines/:id` - Update a pipeline
- `DELETE /api/pipelines/:id` - Delete a pipeline
- `POST /api/pipelines/:id/apply/:context_id` - Apply a pipeline to a context

#### System

- `GET /api/health` - System health check

## Configuration

Configuration is managed through environment-specific files:

- `config/config.exs`: Base configuration
- `config/dev.exs`: Development environment settings
- `config/test.exs`: Test environment settings
- `config/prod.exs`: Production environment settings
- `config/runtime.exs`: Runtime configuration

Key configuration options:

```elixir
# Context size limits
config :mcps_management,
  max_context_size_bytes: 10_485_760,  # 10 MB
  max_contexts_per_user: 1000

# Transformation pipeline
config :mcps_transform,
  max_pipeline_steps: 20,
  max_concurrent_transformations: 10

# Rate limiting
config :mcps_web, :rate_limit,
  max_requests: 100,
  interval_seconds: 60
```

## Development

### Running Tests

```bash
mix test
```

### Generating Documentation

```bash
mix docs
```

### Generating Swagger Documentation

```bash
mix phx.swagger.generate
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.