module.exports = {
  src: [ 'src/js/**/*.js' ],
  tests: [ 'test/**/*.js' ],
  jsx: [ 'tmp/compiled/jsx/**/*.js' ],
  options: {
    force: true,
    jshintrc: 'test/.jshintrc',
    '-W098': true,
    reporter: require('jshint-stylish-ex')
  }
};
