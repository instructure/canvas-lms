# JavaScript Code Coverage

**tl;dr** - If you want to generate a single report for all the code run `RUN_TESTS_FIRST=true yarn run test:coverage`

Because we use several test frameworks, we need to approach code coverage a bit differently.

If you run:

```bash

COVERAGE=true yarn test

```

then you will generate coverage reports for the entire canvas-lms JavaScript codebase including qUnit tests located in
spec/*, jest tests colocated with the app code, and any modules within the canvas-lms/packages directory.
**Note that this will only generate individual coverage reports, not a combined report.**

## Generate Combined Coverage Report

If you want to generate a combined coverage report containing all the information from all the various coverage reports,
then you can do so by running:

```bash

yarn run test:coverage

```

This will generate an HTML report with combined data from all the tests and output it to the `coverage-js`
directory.

**Note however, that this requires you to have previously generated individual coverage reports.**

If you want to ensure that all the coverage reports are generated beforehand, then you want to run:

```bash

RUN_TESTS_FIRST=true yarn run test:coverage

```

which will call `COVERAGE=true yarn test` prior to doing the report.


## Canvas Jest Coverage

If you run:

```bash

yarn run test:jest:coverage

```

then you will run the jest tests for Canvas and the coverage report will be placed in the `coverage-jest` directory.

## Canvas qUnit/Karma Coverage

If you run:

```bash

COVERAGE=true yarn run test:karma

```

then you will run the qUnit/Karma tests for Canvas and the coverage report will be placed in the `coverage-karma` directory.

## Packages Coverage

If you run:

```bash

COVERAGE=true yarn run test:packages

```

then you will generate coverage reports for each package.



## Setting up a package/* for coverage

We make the assumption that you have a `test:coverage` script defined in your package.json.  This script should
generate a coverage report in the `json` format.  Check out https://istanbul.js.org/docs/advanced/alternative-reporters/#json)
for more details on what that should look like.  This report should be output to a `coverage` directory at the root of the
package.


## Caveats

Computers are really good at helping us out but sometimes get it wrong.  If for some reason you are seeing issues, try clearing out the coverage data and starting over.
