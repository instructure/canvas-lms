const formatMessage = require('format-message')

const ns = formatMessage.namespace()

ns.addLocale = (translations) => {
  ns.setup({translations: Object.assign({}, ns.setup().translations, translations)})
}

module.exports = ns

