define([
  'react',
  'instructure-ui/Avatar',
  'instructure-ui/Typography',
], (React, { default: InstUIAvatar }, { default: Typography }) => {

  class Avatar extends React.Component {
    static propTypes = {
      user: React.PropTypes.object.isRequired,
      courseId: React.PropTypes.oneOfType([
        React.PropTypes.string.isRequired,
        React.PropTypes.number.isRequired
      ]),
      canMasquerade: React.PropTypes.bool.isRequired,
    }

    render () {
      const {user, courseId, canMasquerade} = this.props

      if (Object.keys(user).includes('avatar_url')) {
        return (
          <div className="StudentContextTray__Avatar">
            <InstUIAvatar
              size="x-large"
              userName={user.name}
              userImgUrl={user.avatar_url}
            />
            {
              canMasquerade ? (
                <Typography size="x-small" weight="bold" tag="div">
                  <a href={`/courses/${courseId}?become_user_id=${user.id}`}>Masquerade</a>
                </Typography>
              ) : (
                null
              )
            }
          </div>
        )
      } else { return null }
    }
  }

  return Avatar
})
