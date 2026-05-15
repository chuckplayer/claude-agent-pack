# GraphQL Contract Guide (api-designer)

When the project uses GraphQL (detected by `.graphql` files, a `graphql` package dependency, or explicit instruction), produce an SDL contract instead of REST endpoint tables.

## SDL contract must include:

1. **Type definitions** — all object types with field names, scalar types, nullability (`!` for required), and brief inline comments on non-obvious fields.

2. **Operations** — every `Query`, `Mutation`, and `Subscription` the feature requires, with argument types and return types.

3. **Input types** — all `input` types used in mutations, with field-level validation notes as comments.

4. **Enums and scalars** — any custom scalars (e.g., `DateTime`, `UUID`) or enums, with descriptions.

5. **Directives** — any auth or policy directives applied (e.g., `@auth(requires: ADMIN)`), with a note on who owns the directive implementation.

6. **Resolver ownership** — for each type, note which service or layer resolves it (as a comment: `# resolved by: UserService`).

7. **Pagination approach** — state whether the schema uses cursor-based (Relay connection spec) or offset-based pagination, and apply it consistently.

8. **Error shape** — state whether errors use union types (`Result = Success | Error`) or GraphQL extensions, and apply the project's existing pattern.

## Output format

The SDL contract is a `.graphql` file block (not a markdown table). Inline comments (using `#` or `"""` descriptions) document intent for engineer agents.

Close with a **Breaking changes** section (if any existing schema is modified) and a **Security flags** section (if any operations expose sensitive data or require new auth directives).
