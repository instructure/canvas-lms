const formatMessage = require('../format-message')
const contrast = require('wcag-element-contrast')

module.exports = {
  test: (elem) => {
    if (contrast.isLargeText(elem)) {
      return true
    }
    return contrast(elem)
  },

  data: (elem) => {
    const styles = window.getComputedStyle(elem)
    return {
      color: styles.color
    }
  },

  form: () => [{
    label: formatMessage('Change text color'),
    dataKey: 'color',
    color: true
  }],

  update: (elem, data) => {
    elem.style.color = data.color
    return elem
  },

  message: () => formatMessage('Text smaller than 18pt (14pt if bold) should have a minimum contrast ratio of 4.5:1.'),

  why: () => formatMessage(`Paragraph about why color contrast is important.`),

  link: 'https://www.w3.org/TR/UNDERSTANDING-WCAG20/visual-audio-contrast-contrast.html'
}