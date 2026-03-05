# Project Conventions

## Project Overview
- **Name:** [e.g., "Contoso.OrderApi"]
- **Type:** [e.g., ASP.NET Core Web API / Vue 3 SPA / .NET class library]
- **Primary technologies:** [e.g., .NET 8, EF Core 8, SQL Server 2022, Vue 3, TypeScript]

## Solution Structure
- **Namespace root:** [e.g., "Contoso.OrderApi"]
- **Project naming pattern:** [e.g., Contoso.[Domain].[Layer]]
- **Folder conventions:** [e.g., Services/ Repositories/ Entities/ Controllers/]

## Naming Conventions
- **Classes:** [e.g., PascalCase, service suffix: OrderService]
- **Interfaces:** [e.g., I-prefix: IOrderRepository]
- **Files:** [e.g., one class per file, filename matches class name]
- **Database tables:** [e.g., PascalCase plural: Orders, OrderItems]
- **Database columns:** [e.g., PascalCase: OrderId, CreatedAt]

## Architectural Rules
- **Layer boundaries:** [e.g., Controllers call Services only. Services call Repositories.]
- **Patterns in use:** [e.g., Repository pattern, MediatR for commands]
- **Explicitly forbidden:** [e.g., No static classes. No service locator. No DbContext in controllers.]

## Error Handling
- **Strategy:** [e.g., Throw domain exceptions from services, caught in global middleware]
- **HTTP mapping:** [e.g., NotFoundException -> 404, ValidationException -> 400]

## Logging Standards
- **Required fields:** [e.g., CorrelationId, UserId, EntityId on every log entry]
- **Levels:** [e.g., Debug for trace, Information for business events, Error for failures]
- **Correlation:** [e.g., X-Correlation-Id header injected by middleware]

## Testing Conventions
- **Test project naming:** [e.g., Contoso.OrderApi.Tests]
- **Method naming:** [e.g., MethodName_Scenario_ExpectedBehavior]
- **Coverage threshold:** [e.g., 80% line coverage enforced in CI]

## Frontend Conventions
- **Component structure:** [e.g., features/ directory, one folder per feature]
- **Composable naming:** [e.g., use-prefix: useOrderList, useOrderForm]
- **Store organization:** [e.g., one Pinia store per domain]

## Compliance Rules
- **PII handling:** [e.g., Never log CustomerId or email]
- **Audit logging:** [e.g., All mutations on Orders write to AuditLog table]
- **SOX/PCI-DSS:** [e.g., Financial amounts use decimal, never float]
