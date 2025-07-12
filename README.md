# java-learn-by-doing

**Goal**: Learning Java by practical examples

## Planned Task

1. GC analysis in Kubernetes deployment - JDK 17 and JDK 21  🔄
    
    **Focus**: JVM internals, observability, Kubernetes, GC tuning
    **Skills**: JFR, Fluent Bit, Elasticsearch, Grafana, Helm, K3d, GC tuning strategies

    - Deploy app in K8s - using K3d for local development  ✅
    - Use Fluentbit to capture the GC logs  ✅
    - Learn different GC algo and how to tune parameters.
    - Stream data to external source like Elasticsearch + Grafana
    - Comparative Analysis of GC for similar test between version.

2. Java Event-Driven Microservices with Kafka & CQRS ❌

    **Focus**: Build scalable, event-driven microservices using Kafka, with separate command and query models via CQRS. 
    **Skills**: Kafka, Spring Boot, Avro/Protobuf, PostgreSQL, OpenTelemetry, Fluent Bit, Helm, K3d.
    **Description**: Build a microservices-based system that

    - Publishes domain events to Kafka
    - Uses Command Query Responsibility Segregation (CQRS)
    - Has a read-side that aggregates events for quick retrieval


3. Java-based API Gateway with Rate Limiting & JWT Auth ❌

    **Focus**: Design a secure API Gateway with JWT auth, rate limiting, and traffic routing across microservices.
    **Skills**: /Quarkus, Redis, Keycloak, Fluent Bit, OpenTelemetry, Helm, K3d.
    **Description**: Create an API Gateway using Quarkus that:

    - Authenticates requests via JWT
    - Applies rate limiting per user (Redis-backed)
    - Routes requests to downstream services
    - Add circuit breaker/resilience (Resilience4J)


---

✅ Done
🔄 In Progress
❌ Not Started