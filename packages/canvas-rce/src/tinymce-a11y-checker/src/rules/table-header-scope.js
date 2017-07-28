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

  form: [{
    label: 'Set header scope',
    dataKey: 'scope',
    options: [
      ['none', 'None'],
      ['row', 'Row'],
      ['col', 'Column'],
      ['rowgroup', 'Row Group'],
      ['colgroup', 'Column Group'],
    ]
  }],

  update: (elem, data) => {
    if (data.header === 'none') {
      elem.removeAttribute('scope')
      return
    }
    elem.setAttribute('scope', data.scope)
  },

  message: 'Tables headers should have scope specified',

  why: `Paragraph about why table header scope is important.`,

  link: 'https://www.w3.org/TR/WCAG20-TECHS/G95.html'
}