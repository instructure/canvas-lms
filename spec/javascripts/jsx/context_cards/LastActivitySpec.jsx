define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/context_cards/LastActivity',
  'jsx/shared/FriendlyDatetime'
], (React, ReactDOM, TestUtils, LastActivity, FriendlyDatetime) => {

  module('StudentContextTray/LastActivity', (hooks) => {
    let subject
    hooks.afterEach(() => {
      if (subject) {
        const componentNode = ReactDOM.findDOMNode(subject)
        if (componentNode) {
          ReactDOM.unmountComponentAtNode(componentNode.parentNode)
        }
      }
      subject = null
    })

    const lastActivity = "Wed, 16 Nov 2016 00:29:34 UTC +00:00"

    module('lastActivity', () => {
      test('returns null by default', () => {
        subject = TestUtils.renderIntoDocument(
          <LastActivity user={{}} />
        )
        notOk(subject.lastActivity)
      })

      test('returns last activity from collection of enrollment last_activity_at', () => {
        const firstActivity = "Mon, 14 Nov 2016 00:29:34 UTC +00:00"
        const middleActivity = "Tue, 15 Nov 2016 00:29:34 UTC +00:00"

        subject = TestUtils.renderIntoDocument(
          <LastActivity user={{
            enrollments:[{
              last_activity_at: lastActivity
            }, {
              last_activity_at: firstActivity
            }, {
              last_activity_at: middleActivity
            }]
          }} />
        )

        equal(subject.lastActivity, lastActivity)
      })
    })

    test('renders nothing by default', () => {
      subject = TestUtils.renderIntoDocument(
        <LastActivity user={{}} />
      )

      throws(() => {TestUtils.findRenderedComponentWithType(subject, FriendlyDatetime) })
    })

    test('renders friendy date time field when user is present', () => {
      subject = TestUtils.renderIntoDocument(
        <LastActivity user={{
          enrollments:[{
            last_activity_at: lastActivity
          }]
        }} />
      )

      const friendlyDatetime = TestUtils.findRenderedComponentWithType(subject, FriendlyDatetime)
      equal(friendlyDatetime.props.dateTime, lastActivity)
    })
  })
})
