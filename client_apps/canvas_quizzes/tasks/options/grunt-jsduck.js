var grunt = require('grunt');

module.exports = {
  main: {
    src: [ 'apps/*/js/**/*.js', 'tmp/compiled_jsx/**/*.js' ],
    dest: 'doc/api',
    options: {
      'title': "<%= grunt.config.get('pkg.title') %> Reference",
      'builtin-classes': false,
      'color': true,
      'no-source': false,
      'tests': true,
      'processes': 2,
      'warnings': [],
      'guides': 'doc/guides.json',
      'head-html': 'doc/head.html',
      'tags': grunt.file.expand('doc/ext/jsduck/tags/*.rb'),
      'external': [
        'React',
        'React.Component',
        'React.Class',
        'RSVP',
        'RSVP.Promise',
        'jQuery',
        'QTip',
        'qTip',
        'Promise',
      ]
    }
  }
};
