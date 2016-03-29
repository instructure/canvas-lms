module.exports = function(config) {
  config.set({
    basePath: '',
    frameworks: ['mocha', 'chai'],
    files: [
      'test/**/*.spec.js'
    ],
    exclude: [],
    preprocessors: {
      'test/**/*spec.js': [ 'webpack' ]
    },
    webpack: {
      cache: true,
      module: {
        loaders: []
      }
    },
    webpackServer: {
      stats: {
        colors: true
      }
    },
    reporters: [ 'progress' ],
    port: 9876,
    colors: true,
    autoWatch: true,
    singleRun: true,
    browsers: ['Firefox'], // 'PhantomJS','Chrome','Firefox','Safari'
    captureTimeout: 60000,
    plugins: [
      require("karma-mocha"),
      require("karma-chai"),
      require("karma-firefox-launcher"),
      require("karma-webpack")
    ]
  });
};
