# Make a JavaScript test suite more stable

* Wait for async operations to complete
* Ensure proper cleanup after each test
* Improve query selectors if needed
* Use data-testid for more reliable element selection
* Remove flaky tests that only look for spinners or progress bars

Run using `yarn jest —randomize [file]` to confirm afterwards.