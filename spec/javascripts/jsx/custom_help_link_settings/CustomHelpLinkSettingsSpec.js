define([
  'react',
  'react-dom',
  'jsx/custom_help_link_settings/CustomHelpLinkSettings'
], (React, ReactDOM, CustomHelpLinkSettings) => {

  const container = document.getElementById('fixtures')

  QUnit.module('<CustomHelpLinkSettings/>', {
    render(overrides={}) {
      const props = {
        name: 'Help',
        icon: 'help',
        links: [],
        defaultLinks: [
          {
            available_to: ['student'],
            text: 'Ask Your Instructor a Question',
            subtext: 'Questions are submitted to your instructor',
            url: '#teacher_feedback',
            type: 'default'
          },
          {
            available_to: ['user','student','teacher','admin'],
            text: 'Search the Canvas Guides',
            subtext: 'Find answers to common questions',
            url: 'http://community.canvaslms.com/community/answers/guides',
            type: 'default'
          },
          {
            available_to: ['user','student','teacher','admin'],
            text: 'Report a Problem',
            subtext: 'If Canvas misbehaves, tell us about it',
            url: '#create_ticket',
            type: 'default'
          }
        ],
        ...overrides
      }

      return ReactDOM.render(<CustomHelpLinkSettings {...props} />, container)
    },
    teardown() {
      ReactDOM.unmountComponentAtNode(container)
    }
  })

  test('render()', function () {
    const subject = this.render()
    ok(ReactDOM.findDOMNode(subject))
  })

  test('accepts properly formatted urls', function () {
    const subject = this.render()

    let link = {
      text: 'test link',
      available_to: ['user', 'student', 'teacher', 'admin'],
      url: ''
    }

    link.url = 'http://testurl.com'
    ok(subject.validate(link))

    link.url = 'https://testurl.com'
    ok(subject.validate(link))

    link.url = 'ftp://test.url/.test'
    ok(subject.validate(link))

    link.url = 'tel:1-999-999-9999'
    ok(subject.validate(link))

    link.url = 'mailto:test@test.com'
    ok(subject.validate(link))
  })
})
