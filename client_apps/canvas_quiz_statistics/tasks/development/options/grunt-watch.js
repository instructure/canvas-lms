module.exports = {
  options: {
    spawn: false,
  },

  css: {
    files: '{src,vendor}/css/**/*.{scss,css}',
    tasks: [ 'compile_css' ],
    options: {
      spawn: true
    }
  },

  compiled_css: {
    files: 'dist/*.css',
    tasks: [ 'noop' ],
    options: {
      livereload: {
        port: 9224
      }
    }
  },

  jsx: {
    files: 'src/js/**/*.jsx',
    tasks: [ 'newer:react:dev', 'jshint:jsx' ]
  },

  tests: {
    files: [ 'src/js/**/*.j{s,sx}', 'test/**/*', 'tasks/*.js', 'vendor/packages/**/*.js' ],
    tasks: [ 'jasmine:unit' ],
  },
};
