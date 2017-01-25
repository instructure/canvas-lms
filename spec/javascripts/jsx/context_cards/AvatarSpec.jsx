define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/context_cards/Avatar',
  'instructure-ui/Avatar'
], (React, ReactDOM, TestUtils, Avatar, { default: InstUIAvatar }) => {

  module('StudentContextTray/Avatar', (hooks) => {
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

    test('renders no avatars by default', () => {
      subject = TestUtils.renderIntoDocument(
        <Avatar
          user={{}}
        />
      )

      throws(() => {TestUtils.findRenderedComponentWithType(subject, InstUIAvatar) })
    })

    test('renders avatar with user object when provided', () => {
      const userName = 'wooper'
      const avatarUrl = 'http://wooper.com/avatar.png'
      const user = {
        name: userName,
        avatar_url: avatarUrl
      }
      subject = TestUtils.renderIntoDocument(
        <Avatar
          user={{...user}}
        />
      )

      const avatar = TestUtils.findRenderedComponentWithType(subject, InstUIAvatar)
      equal(avatar.props.userName, user.name)
      equal(avatar.props.userImgUrl, user.avatar_url)
    })
  })
})
