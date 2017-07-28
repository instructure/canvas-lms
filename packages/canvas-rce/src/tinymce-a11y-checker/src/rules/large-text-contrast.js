const formatMessage = require('../format-message')
const contrast = require('wcag-element-contrast')
const smallTextContrast = require('./small-text-contrast')

module.exports = {
  test: (elem) => {
    if (!contrast.isLargeText(elem)) {
      return true
    }
    return contrast(elem)
  },

  data: smallTextContrast.data,

  form: smallTextContrast.form,

  update: smallTextContrast.update,

  message: () => formatMessage('Text 18pt (14pt if bold) or larger should have a minimum contrast ratio of 3:1.'),

  why: () => formatMessage(`Paragraph about why color contrast is important.`),

  link: 'https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html'
}