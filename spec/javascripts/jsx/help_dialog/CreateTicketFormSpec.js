define([
  'react',
  'react-dom',
  'jsx/help_dialog/CreateTicketForm'
], (React, ReactDOM, CreateTicketForm) => {

  const container = document.getElementById('fixtures')

  QUnit.module('<CreateTicketForm/>', {
    render(overrides={}) {
      const props = {
        ...overrides
      }

      return ReactDOM.render(<CreateTicketForm {...props} />, container)
    },
    teardown() {
      ReactDOM.unmountComponentAtNode(container)
    }
  })

  test('render()', function () {
    const subject = this.render()
    ok(ReactDOM.findDOMNode(subject))
  })
})
