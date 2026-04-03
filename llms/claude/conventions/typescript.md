# TypeScript / JavaScript Conventions

## Testing

- Use `jest-mock-extended`'s `mock<T>()` to create mocks instead of manually duck-typing interface members as `jest.fn()`. It's less boilerplate and automatically stays in sync when the interface changes.
- Follow the test context pattern from `testing.md`. In TypeScript: declare `let testCtx` typed via `ReturnType<typeof createTestCtx>`, define a factory function that constructs and returns all setup state, and call it in `beforeEach`. Naming is flexible as long as the pattern is clear. Example:

```typescript
function createTestCtx() {
  const mockRepo = mock<UserRepo>();
  const service = new UserService(mockRepo);
  return { mockRepo, service };
}

let testCtx: ReturnType<typeof createTestCtx>;

beforeEach(() => {
  testCtx = createTestCtx();
});
```

## Linting

- Before committing changes to a TypeScript or JavaScript project, check `package.json` for lint scripts (e.g. `lint`, `lint:fix`, `eslint`, `prettier`, `format`).
- If lint scripts exist, run them and fix all reported issues before considering the task complete.
- Do NOT disable or suppress linter rules to make code pass. Fix the underlying issue instead.
- If a linter rule seems wrong for the situation, raise it with the team rather than adding a disable comment.
