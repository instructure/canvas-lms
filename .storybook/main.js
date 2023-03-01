const path = require('path')
const glob = require('glob')
const baseWebpackConfig = require('../ui-build/webpack')
const { canvasDir } = require('../ui-build/params')
const WebpackHooks = require('../ui-build/webpack/webpackHooks')

const root = path.resolve(__dirname, '..')

function globPlugins(pattern) {
  return glob.sync(`gems/plugins/*/${pattern}`, {
    absolute: true,
    cwd: canvasDir
  })
}

module.exports = {
  logLevel: 'debug',
  stories: [
    '../ui/**/*.stories.mdx',
    '../ui/**/*.stories.@(js|jsx|ts|tsx)'
  ],
  addons: [
    '@storybook/addon-links',
    '@storybook/addon-essentials'
  ],
  core: {
    builder: 'webpack5',
  },
  webpackFinal: async (config) => {
    config.module.noParse = [/i18nliner\/dist\/lib\/i18nliner/]
    config.target = baseWebpackConfig.target
    config.resolve.modules = baseWebpackConfig.resolve.modules
    config.resolve.alias = {...baseWebpackConfig.resolve.alias, ...config.resolve.alias}
    config.module.rules = [
      {
        test: /\.m?js$/,
        type: 'javascript/auto',
        include: [
          path.resolve(canvasDir, 'node_modules/graphql'),
          path.resolve(canvasDir, 'packages/datetime-moment-parser/index.js'),
          path.resolve(canvasDir, 'packages/datetime/index.js'),
        ],
        resolve: {
          fullySpecified: false
        }
      },
      {
        test: /\.js$/,
        type: 'javascript/auto',
        include: [
          path.resolve(canvasDir, 'node_modules/@instructure'),
        ]
      },
      {
        test: /\.(js|ts|tsx)$/,
        include: [
          path.resolve(canvasDir, 'ui'),
          path.resolve(canvasDir, 'packages/jquery-kyle-menu'),
          path.resolve(canvasDir, 'packages/jquery-popover'),
          path.resolve(canvasDir, 'packages/jquery-selectmenu'),
          path.resolve(canvasDir, 'packages/jquery-sticky'),
          path.resolve(canvasDir, 'packages/mathml'),
          path.resolve(canvasDir, 'packages/defer-promise'),
          path.resolve(canvasDir, 'packages/convert-case'),
          path.resolve(canvasDir, 'packages/html-escape'),
          path.resolve(canvasDir, 'packages/persistent-array'),
          path.resolve(canvasDir, 'packages/slickgrid'),
          path.resolve(canvasDir, 'packages/with-breakpoints'),
          path.resolve(canvasDir, 'spec/javascripts/jsx'),
          path.resolve(canvasDir, 'spec/coffeescripts'),
          path.resolve(canvasDir, '.storybook'),
          ...globPlugins('app/{jsx,coffeescripts}/'),
        ],
        exclude: [/node_modules/],
        parser: {
          requireInclude: 'allow'
        },
        use: {
          loader: 'babel-loader',
          options: {
            configFile: false,
            cacheDirectory: process.env.NODE_ENV !== 'production',
            assumptions: {
              setPublicClassFields: true
            },
            env: {
              development: {
                plugins: ['babel-plugin-typescript-to-proptypes']
              },
              production: {
                plugins: [
                  ['@babel/plugin-transform-runtime', {
                    helpers: true,
                    corejs: 3,
                    useESModules: true
                  }],
                  'transform-react-remove-prop-types',
                  '@babel/plugin-transform-react-inline-elements',
                  '@babel/plugin-transform-react-constant-elements'
                ]
              }
            },
            presets: [
              ['@babel/preset-typescript'],
              ['@babel/preset-env', {
                useBuiltIns: 'entry',
                corejs: '3.20',
                modules: false
              }],
              ['@babel/preset-react', { useBuiltIns: true }]
            ],
            targets: {
              browsers: 'last 2 versions',
              esmodules: true
            }
          }
        }
      },
      {
        test: /\.coffee$/,
        include: [
          path.resolve(canvasDir, 'ui'),
          path.resolve(canvasDir, 'spec/coffeescripts'),
          ...globPlugins('{app,spec_canvas}/coffeescripts/')
        ],
        use: ['coffee-loader']
      },
      {
        test: /\.handlebars$/,
        include: [
          path.resolve(canvasDir, 'ui'),
          ...globPlugins('app/views/jst/'),
        ],
        use: [
          {
            loader: require.resolve('../ui-build/webpack/i18nLinerHandlebars'),
            options: {
              // brandable_css assets are not available in test
              injectBrandableStylesheet: process.env.NODE_ENV !== 'test'
            }
          }
        ]
      },
      {
        test: /\.css$/,
        use: ['style-loader', 'css-loader']
      },
      {
        test: /\.(png|svg|gif)$/,
        loader: 'file-loader'
      },
      {
        test: /\.(woff(2)?|otf|ttf|eot)(\?v=[0-9]\.[0-9]\.[0-9])?$/,
        use: 'file-loader'
      }
    ]

    config.plugins = [
      ...config.plugins,
      new WebpackHooks()
    ]
    return config
  }
}

