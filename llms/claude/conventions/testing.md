# Testing Conventions

- Tests MUST cover the functionality being implemented.
- NEVER ignore the output of the system or the tests - Logs and messages often contain CRITICAL information.
- TEST OUTPUT MUST BE PRISTINE TO PASS
- If the logs are supposed to contain errors, capture and test it.
- NO EXCEPTIONS POLICY: Under no circumstances should you mark any test type as "not applicable". Every project, regardless of size or complexity, MUST have unit tests, integration tests, AND end-to-end tests. If you believe a test type doesn't apply, you need the human to say exactly "I AUTHORIZE YOU TO SKIP WRITING TESTS THIS TIME"

## Test context

All test setup state must be collected into a single context object (e.g. `testCtx`, `ctx`, `TestCtx`). It must be initialized before each test via a dedicated initializer — a factory function, constructor, or equivalent. Setup variables must not be declared individually and scattered across the describe/test scope.

**Why:** scattered setup variables are easy to forget to reinitialize, which causes state to bleed between tests (safety). A single context object is one place to look for all setup state (readability), and a consistent pattern across suites makes tests easier to navigate and review (uniformity).

## We practice TDD. That means:

- Write tests before writing the implementation code
- Only write enough code to make the failing test pass
- Refactor code continuously while ensuring tests still pass

### TDD Implementation Process

- Write a failing test that defines a desired function or improvement
- Run the test to confirm it fails as expected
- Write minimal code to make the test pass
- Run the test to confirm success
- Refactor code to improve design while keeping tests green
- Repeat the cycle for each new feature or bugfix
