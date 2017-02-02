define([
  'react',
  'react-dom',
  'react-addons-test-utils',
  'jsx/context_cards/Avatar',
  'instructure-ui'
], (React, ReactDOM, TestUtils, Avatar, { Avatar: InstUIAvatar }) => {
  QUnit.module('StudentContextTray/Avatar', (hooks) => {
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
          user={{}} courseId="1" canMasquerade
        />
      )

      throws(() => { TestUtils.findRenderedComponentWithType(subject, InstUIAvatar) })
    })

    test('renders avatar with user object when provided', () => {
      const userName = 'wooper'
      const avatarUrl = 'http://wooper.com/avatar.png'
      const user = {
        name: userName,
        avatar_url: avatarUrl,
        id: '17'
      }
      subject = TestUtils.renderIntoDocument(
        <Avatar
          user={{...user}} courseId="1" canMasquerade
        />
      )

      const avatar = TestUtils.findRenderedComponentWithType(subject, InstUIAvatar)
      equal(avatar.props.userName, user.name)
      equal(avatar.props.userImgUrl, user.avatar_url)
      const componentNode = ReactDOM.findDOMNode(subject)
      const link = componentNode.querySelector('a')
      equal(link.getAttribute('href'), '/courses/1/users/17')
    })
  })
})
