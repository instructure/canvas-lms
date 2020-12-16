const I18nPlugin = require('../frontend_build/i18nPlugin')
const path = require('path')
const baseWebpackConfig = require('../frontend_build/baseWebpackConfig')
const CompiledReferencePlugin = require('../frontend_build/CompiledReferencePlugin')

const root = path.resolve(__dirname, '..')

module.exports = {
  "stories": [
    "../app/jsx/**/*.stories.mdx",
    "../app/jsx/**/*.stories.@(js|jsx|ts|tsx)"
  ],
  "addons": [
    "@storybook/addon-links",
    "@storybook/addon-essentials"
  ],
  "webpackFinal": async (config, { configType }) => {
    config.module.noParse = [/i18nliner\/dist\/lib\/i18nliner/]
    config.plugins.push(
      new I18nPlugin()
    );
    config.plugins.push(
      new CompiledReferencePlugin(),
    );
    config.resolveLoader.modules = [
      path.resolve(__dirname, '../public/javascripts/'),
      path.resolve(__dirname, '../app/coffeescripts/'),
      path.resolve(__dirname, '../frontend_build/'),
      'node_modules'
    ]
    config.resolve.modules = [
      path.resolve(__dirname, '../public/javascripts/'),
      path.resolve(__dirname, '../app/coffeescripts'),
      path.resolve(__dirname, '../frontend_build/'),
      'node_modules'
    ]
    config.resolve.alias['coffeescripts/str/i18nLolcalize.js'] = path.resolve(__dirname, '../app/coffeescripts/str/i18nLolcalize.js')
    return config;
  }
}