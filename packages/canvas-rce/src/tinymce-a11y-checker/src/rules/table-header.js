const formatMessage = require('../format-message')
const dom = require('../utils/dom')

const _forEach = Array.prototype.forEach

module.exports = {
  test: (elem) => {
    if (elem.tagName !== 'TABLE') {
      return true
    }
    return elem.querySelector('th')
  },

  data: (elem) => {
    return {
      header: 'none'
    }
  },

  form: () => [{
    label: formatMessage('Set table header'),
    dataKey: 'header',
    options: [
      ['none', formatMessage('No Headers')],
      ['row', formatMessage('Header Row')],
      ['col', formatMessage('Header Column')],
      ['both', formatMessage('Header Row and Column')]
    ]
  }],

  update: (elem, data) => {
    _forEach.call(elem.querySelectorAll('th'), (th) => {
      dom.changeTag(th, 'td')
    })
    if (data.header === 'none') {
      return
    }
    const row = data.header === 'row' || data.header === 'both'
    const col = data.header === 'col' || data.header === 'both'
    const tableRows = elem.querySelectorAll('tr')
    for (let i = 0; i < tableRows.length; ++i) {
      if (i === 0 && row) {
        _forEach.call(tableRows[i].querySelectorAll('td'), (td) => {
          const th = dom.changeTag(td, 'th')
          th.setAttribute('scope', 'col')
        })
        continue
      }
      if (!col) {
        break
      }
      const td = tableRows[i].querySelector('td')
      if (td) {
        const th = dom.changeTag(td, 'th')
        th.setAttribute('scope', 'row')
      }
    }
  },

  message: () => formatMessage('Tables should have at least one header'),

  why: () => formatMessage(`Paragraph about why table headers are important.`),

  link: 'https://www.w3.org/TR/WCAG20-TECHS/G95.html'
}