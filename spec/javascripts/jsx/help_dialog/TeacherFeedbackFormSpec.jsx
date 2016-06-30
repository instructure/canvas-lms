define([
  'react',
  'react-dom',
  'jquery',
  'jsx/help_dialog/TeacherFeedbackForm',
  'jquery.ajaxJSON'
], (React, ReactDOM, jQuery, TeacherFeedbackForm) => {

  const container = document.getElementById('fixtures')
  let server

  module('<TeacherFeedbackForm/>', {
    setup () {
      server = sinon.fakeServer.create()

      // This is a POST rather than a PUT because of the way our $.getJSON converts
      // non-GET requests to posts anyways.
      server.respondWith('GET', /api\/v1\/courses.json/,
        [200, { "Content-Type": "application/json" }, JSON.stringify([])]
      );

      this.stub(jQuery, 'ajaxJSON')
    },
    render (overrides={}) {
      const props = {
        ...overrides
      }

      return ReactDOM.render(<TeacherFeedbackForm {...props} />, container)
    },
    teardown() {
      ReactDOM.unmountComponentAtNode(container)
      server.restore()
    }
  })

  test('render()', function () {
    const subject = this.render()
    ok(ReactDOM.findDOMNode(subject))

    server.respond()
  })
})
