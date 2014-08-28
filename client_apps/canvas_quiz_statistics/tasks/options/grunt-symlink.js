module.exports = {
  options: {
    overwrite: true
  },

  compiled: {
    files: [{
      src: 'tmp/compiled',
      dest: 'tmp/js/canvas_quiz_statistics/compiled'
    }],
  },

  development: {
    options: {
      overwrite: false
    },

    files: [{
      src: '../../',
      dest: 'vendor/canvas'
    }, {
      expand: true,
      src: '{src,dist,vendor}',
      dest: 'www/',
    }, {
      expand: true,
      cwd: '../../public',
      src: '{font,images}',
      dest: 'www/'
    }, {
      src: 'test/fixtures',
      dest: 'www/fixtures'
    }]
  },

  assets: {
  }
};