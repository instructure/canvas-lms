# Testing JavaScript

## Filename Conventions
Place test files or `__tests__` folders next to the code being tested for shorter relative imports.

### Writing Jest Tests
Use `it()` or `test()` blocks with assertions via `expect()`. Example:
  ```js
  import sum from './sum'
  it('sums numbers', () => {
    expect(sum(1, 2)).toEqual(3)
    expect(sum(2, 2)).toEqual(4)
  })
  ```

### Running Tests
- Run all tests: `yarn test`
- Run first 10% of tests: `yarn test --shard=1/10`
- Run specific tests: `yarn test path/to/test`

### Coverage Reporting
Run `npm test -- --coverage` for a coverage report.

## Tips
* @instructure/foo module (generally) lives in packages/foo
* @canvas/foo module lives in ui/shared/foo
* Follow the Arrange-Act-Assert pattern.
* Use testing-library, not React Testing Library or react-dom/test-utils
* Tests should be resilient to change of year, month, and day.
* Keep tests independent. One test should not depend on the result of another.
* testing-library docs say: “getByRole performance can be improved by setting the option hidden to true and thereby avoid expensive visibility checks. Note that in doing so inaccessible elements will now be included in the result. Another option may be to substitute getByRole for simpler getByLabelText and getByText queries which can be significantly faster though less robust alternatives.”
  * Hence prefer testing by data-testid over roles for now
  * Otherwise, prefer Testing Library recommendations
* Prefer userEvent over fireEvent
* Prefer testing user interactions and results instead of implementation details.
* Using meaningful assertions
* Mock only what is necessary.
* With testing-library, destructure get/find from render() instead of using screen methods
* Clean up after each test
* Prefer native DOM API over jQuery for construction of HTML
* Use msw for mocking network requests
* jest-axe isn’t available. use axe-core if needed
* Avoid using mockResolvedValue and mockImplementation; better to mock directly in the mock definition at the top of the file.
* Try to keep test files under 300 lines
* Use `import fakeENV from '@canvas/test-utils/fakeENV'` to test window.ENV

## Do not
* Don't test mocks.
* Don't test spinners.
* Don't mock @canvas/i18n, React, ReactDOM
* Don’t exceed or increase the default timeout.