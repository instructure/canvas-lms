define([
  'i18n!student_context_tray',
  'react',
  'instructure-ui',
], (I18n, React, { Avatar: InstUIAvatar, Typography }) => {
  class Avatar extends React.Component {
    static propTypes = {
      user: React.PropTypes.shape({
        name: React.PropTypes.string,
        avatar_url: React.PropTypes.string,
        short_name: React.PropTypes.string,
        id: React.PropTypes.string
      }).isRequired,
      courseId: React.PropTypes.oneOfType([
        React.PropTypes.string,
        React.PropTypes.number
      ]).isRequired,
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
                <Typography size="x-small" weight="bold" as="div">
                  <a
                    href={`/courses/${courseId}?become_user_id=${user.id}`}
                    aria-label={I18n.t('Masquerade as %{name}', { name: user.short_name })}
                  >
                    {I18n.t('Masquerade')}
                  </a>
                </Typography>
              ) : (
                null
              )
            }
          </div>
        )
      }
      return null
    }
  }

  return Avatar
})
