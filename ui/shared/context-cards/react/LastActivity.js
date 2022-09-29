/*
 * Copyright (C) 2016 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import React from 'react'
import PropTypes from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'

const I18n = useI18nScope('student_context_trayLastActivity')

class LastActivity extends React.Component {
  static propTypes = {
    user: PropTypes.object.isRequired,
  }

  get lastActivity() {
    if (typeof this.props.user.enrollments === 'undefined') {
      return null
    }

    const lastActivityStrings = this.props.user.enrollments.map(enrollment => {
      return enrollment.last_activity_at
    })
    const sortedActivity = lastActivityStrings.sort((a, b) => {
      return new Date(a).getTime() - new Date(b).getTime()
    })
    return sortedActivity[sortedActivity.length - 1]
  }

  render() {
    const lastActivity = this.lastActivity

    if (lastActivity) {
      return (
        <span>
          {I18n.t('Last login:')} <FriendlyDatetime dateTime={lastActivity} />
        </span>
      )
    } else {
      return null
    }
  }
}

export default LastActivity
