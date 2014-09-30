module.exports = {
  dist: {
    options: {
      style: 'expanded',
      includePaths: [
        'vendor/canvas/app/stylesheets',
        'vendor/canvas/app/stylesheets/variants/new_styles_normal_contrast'
      ],
      outputStyle: 'nested'
    },
    files: {
      'dist/canvas_quiz_statistics.css': 'src/css/app.scss',
    }
  }
};