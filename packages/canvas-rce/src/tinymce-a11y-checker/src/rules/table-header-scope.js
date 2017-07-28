const formatMessage = require('../format-message')

const VALID_SCOPES = ['row', 'col', 'rowgroup', 'colgroup']

module.exports = {
  test: (elem) => {
    if (elem.tagName !== 'TH') {
      return true
    }
    return VALID_SCOPES.indexOf(elem.getAttribute('scope')) !== -1
  },

  data: (elem) => {
    return {
      scope: elem.getAttribute('scope') || 'none'
    }
  },

  form: () => [{
    label: formatMessage('Set header scope'),
    dataKey: 'scope',
    options: [
      ['none', formatMessage('None')],
      ['row', formatMessage('Row')],
      ['col', formatMessage('Column')],
      ['rowgroup', formatMessage('Row Group')],
      ['colgroup', formatMessage('Column Group')],
    ]
  }],

  update: (elem, data) => {
    if (data.header === 'none') {
      elem.removeAttribute('scope')
      return
    }
    elem.setAttribute('scope', data.scope)
  },

  message: () => formatMessage('Tables headers should have scope specified'),

  why: () => formatMessage(`Paragraph about why table header scope is important.`),

  link: 'https://www.w3.org/TR/WCAG20-TECHS/G95.html'
}