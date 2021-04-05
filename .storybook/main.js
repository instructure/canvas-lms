const I18nPlugin = require('../frontend_build/i18nPlugin')
const path = require('path')
const baseWebpackConfig = require('../frontend_build/baseWebpackConfig')

const root = path.resolve(__dirname, '..')

module.exports = {
  stories: [
    '../ui/**/*.stories.mdx',
    '../ui/**/*.stories.@(js|jsx|ts|tsx)'
  ],
  addons: [
    '@storybook/addon-links',
    '@storybook/addon-essentials'
  ],
  webpackFinal: async (config) => {
    config.module.noParse = [/i18nliner\/dist\/lib\/i18nliner/]
    config.plugins.push(new I18nPlugin())
    config.resolveLoader.modules = [
      path.resolve(__dirname, '../public/javascripts/'),
      path.resolve(__dirname, '../app/coffeescripts/'),
      path.resolve(__dirname, '../frontend_build/'),
      'node_modules'
    ]
    config.resolve.modules = [
      path.resolve(__dirname, '../public/javascripts/'),
      path.resolve(__dirname, '../app/coffeescripts'),
      path.resolve(__dirname, '../frontend_build/shims'),
      path.resolve(__dirname, '../frontend_build/'),
      'node_modules'
    ]
    config.resolve.alias['coffeescripts'] = path.resolve(__dirname, '../app/coffeescripts')
    config.resolve.alias['node_modules-version-of-react-modal'] = require.resolve('react-modal')
    config.resolve.alias['node_modules-version-of-backbone'] = require.resolve('backbone')
    config.resolve.alias = {...baseWebpackConfig.resolve.alias, ...config.resolve.alias}
    config.module.rules = [
      ...config.module.rules,
      {
        test: /\.coffee$/,
        include: [
          path.resolve(__dirname, '../app/coffeescript'),
          path.resolve(__dirname, '../spec/coffeescripts'),
          /app\/coffeescripts\//,
          /gems\/plugins\/.*\/spec_canvas\/coffeescripts\//
        ],
        loaders: ['coffee-loader']
      },
      {
        test: /\.handlebars$/,
        include: [
          path.resolve(__dirname, '../app/views/jst'),
          /gems\/plugins\/.*\/app\/views\/jst\//
        ],
        loaders: ['i18nLinerHandlebars']
      }
    ]

    return config
  }
}
