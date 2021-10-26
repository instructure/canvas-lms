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
      path.resolve(__dirname, '../frontend_build/'),
      'node_modules'
    ]

    config.resolve.modules = [
      path.resolve(__dirname, '../ui/shims'),
      path.resolve(__dirname, '../public/javascripts'), // for translations
      'node_modules'
    ]
    config.resolve.alias = {...baseWebpackConfig.resolve.alias, ...config.resolve.alias}
    config.module.rules = [
      ...config.module.rules,
      {
        test: /\.coffee$/,
        include: [path.resolve(__dirname, '../ui')],
        loaders: ['coffee-loader']
      },
      {
        test: /\.handlebars$/,
        include: [path.resolve(__dirname, '../ui')],
        loaders: ['i18nLinerHandlebars']
      }
    ]

    return config
  }
}
