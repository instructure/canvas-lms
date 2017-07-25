module.exports = {
  test: (elem) => {
    const a11y = elem.attributes.getNamedItem('data-a11y')
    return a11y && a11y.value === 'valid'
  },

  data: (elem) => {
    const a11y = elem.attributes.getNamedItem('data-a11y')
    return {
      a11y: a11y ? a11y.value : ''
    }
  },

  form: [{
    label: 'A11y',
    options: [['invalid', 'Not Valid'], ['valid', 'This is valid']],
    dataKey: 'a11y'
  }],

  update: (elem, data) => {
    elem.setAttribute('data-a11y', data.a11y)
    return elem
  },

  message: 'You should make this element more accessible',

  why: `This is be a longer bit of text to explain why this rule is important
        and how it will help users with a disability. It can help people learn.`,

  link: 'https://www.w3.org/TR/WCAG20-TECHS/G95.html'
}