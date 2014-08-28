var grunt = require('grunt');

module.exports = {
  main: {
    src: [ 'src/js', 'src/css', 'tmp/compiled/**/*.js' ],
    dest: 'doc/api',
    options: {
      'title': "<%= grunt.appName %> Reference",
      'builtin-classes': false,
      'color': true,
      'no-source': true,
      'tests': false,
      'processes': 2,
      'warnings': [],
      'external': [
        'React',
      ]
    }
  }
};
