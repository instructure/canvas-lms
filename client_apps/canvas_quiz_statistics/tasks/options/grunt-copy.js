module.exports = {
  src: {
    files: [
      {
        expand: true,
        cwd: 'src/js/',
        src: '**/*',
        dest: 'tmp/js/canvas_quiz_statistics'
      }
    ]
  },
  map: {
    files: [{
      src: 'vendor/packages/map.json',
      dest: 'dist/canvas_quiz_statistics.map.json'
    }]
  }
};