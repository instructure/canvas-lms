import React from 'react'
import I18n from 'i18n!student_context_tray'
import FriendlyDatetime from 'jsx/shared/FriendlyDatetime'

  class LastActivity extends React.Component {
    static propTypes = {
      user: React.PropTypes.object.isRequired
    }

    get lastActivity () {
      if (typeof this.props.user.enrollments === 'undefined') {
        return null
      }

      const lastActivityStrings = this.props.user.enrollments.map((enrollment) => {
        return enrollment.last_activity_at
      })
      const sortedActivity = lastActivityStrings.sort((a,b) => {
        return new Date(a).getTime() - new Date(b).getTime()
      })
      return sortedActivity[sortedActivity.length - 1]
    }

    render () {
      const lastActivity = this.lastActivity

      if (lastActivity) {
        return (
          <span>{I18n.t('Last login:')} <FriendlyDatetime dateTime={lastActivity} /></span>
        )
      } else { return null }
    }
  }

export default LastActivity
