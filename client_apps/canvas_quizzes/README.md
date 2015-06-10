# canvas-quizzes

A collection of quiz mini-apps for Canvas, the LMS by Instructure.

See the [development guide](https://github.com/amireh/canvas_quiz_statistics/wiki/Development-Guide) to get started.

## Dependencies

1. React
2. lodash / underscore
3. RSVP
4. d3

## Running tests

Each app has its own suite. You can run all suites using `grunt test`. If you want to run the suite for a single app, write down its name. For example: `grunt test:events`.

If you want to filter specs that are run within a suite, use `--filter="test_file_name.js"`. See [grunt-contrib-jasmine](https://github.com/gruntjs/grunt-contrib-jasmine#filtering-specs) for a complete reference.

## License

Released under the AGPLv3 license, like [Canvas](http://github.com/instructure/canvas-lms).