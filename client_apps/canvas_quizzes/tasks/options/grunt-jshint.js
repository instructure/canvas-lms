module.exports = {
  src: [ 'apps/*/js/**/*.js' ],
  tests: [ 'apps/*/test/**/*_test.js' ],
  jsx: [ 'tmp/compiled/jsx/**/*.js' ],

  options: {
    force: true,
    '-W098': true,
    reporter: require('jshint-stylish-ex')
  }
};
