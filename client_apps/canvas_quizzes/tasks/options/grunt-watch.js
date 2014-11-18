module.exports = {
  options: {
    spawn: false,
  },

  css: {
    files: '{apps/*/css,vendor/css}/**/*.{scss,css}',
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

  tests: {
    files: [
      'apps/*/js/**/*.j{s,sx}',
      'tasks/*.js',
      'vendor/packages/**/*.js'
    ],
    tasks: [ 'jasmine' ],
  },
};
