const env = process.env.BABEL_ENV || process.env.NODE_ENV;

if (env === 'test') {
  module.exports = {
    presets: [
      ['env', {
        modules: 'commonjs',
        // use the same polyfills we use in the code we send to browsers
        targets: { browsers: require('@instructure/canvas-supported-browsers') }
      }],
      'stage-1',
      'react'
    ],
    plugins: [
      'transform-class-display-name',
      'transform-node-env-inline'
    ]
  };
} else {
  module.exports = {
    // eslint-disable-next-line import/no-extraneous-dependencies
    presets: [[ require('@instructure/ui-presets/babel'), {
      themeable: true,
      coverage: false,
      esModules: true
    }]]
  };
}
