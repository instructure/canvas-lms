import I18n from 'i18n!student_context_tray'
import React from 'react'
import InstUIAvatar from 'instructure-ui/lib/components/Avatar'
import Typography from 'instructure-ui/lib/components/Typography'
import Link from 'instructure-ui/lib/components/Link'

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
        const name = user.short_name || user.name || 'user';
        return (
          <div className="StudentContextTray__Avatar">
            <Link href={`/courses/${this.props.courseId}/users/${user.id}`} aria-label={I18n.t('Go to %{name}\'s profile', {name})}>
              <InstUIAvatar
                size="x-large"
                userName={user.name}
                userImgUrl={user.avatar_url}
              />
            </Link>
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

export default Avatar
