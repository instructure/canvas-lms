module.exports = {
  dist: {
    options: {
      style: 'expanded',
      includePaths: [
        'vendor/canvas_app/stylesheets',
        'vendor/canvas_app/stylesheets/variants/new_styles_normal_contrast'
      ],
      outputStyle: 'nested'
    },

    files: {
      "dist/<%= grunt.config.get('pkg.name') %>.css": 'apps/common/css/main.scss',
    }
  }
};