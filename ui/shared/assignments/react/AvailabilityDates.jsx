/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import PropTypes from 'prop-types'

import FriendlyDatetime from '@canvas/datetime/react/components/FriendlyDatetime'
import ConnectedFriendlyDatetimes from '@canvas/datetime/react/components/ConnectedFriendlyDatetimes'

const I18n = useI18nScope('assignments_2')

export default function AvailabilityDates({assignment, formatStyle}) {
  const longFmt = formatStyle === 'long'

  if (assignment.lockAt && assignment.unlockAt) {
    return (
      // ConnectedFriendlyDatetimes was needed to work around voiceover either smashing the two times together or
      // treating the times as two different elements. This new element works around this.
      <ConnectedFriendlyDatetimes
        prefix={longFmt ? I18n.t('Available:') : ''}
        firstDateTime={assignment.unlockAt}
        secondDateTime={assignment.lockAt}
        format={longFmt ? I18n.t('#date.formats.full') : I18n.t('#date.formats.short')}
        connector={longFmt ? I18n.t('until') : I18n.t('to')}
        connectorMobile={I18n.t('to')}
      />
    )
  } else if (assignment.lockAt) {
    return (
      <FriendlyDatetime
        prefix={I18n.t('Available until')}
        dateTime={assignment.lockAt}
        format={longFmt ? I18n.t('#date.formats.full') : I18n.t('#date.formats.short')}
      />
    )
  } else if (assignment.unlockAt) {
    return (
      <FriendlyDatetime
        prefix={I18n.t('Available after')}
        dateTime={assignment.unlockAt}
        format={longFmt ? I18n.t('#date.formats.full') : I18n.t('#date.formats.short')}
      />
    )
  } else {
    return null
  }
}

AvailabilityDates.propTypes = {
  assignment: PropTypes.shape({
    lockAt: PropTypes.string,
    unlockAt: PropTypes.string,
  }).isRequired,
  formatStyle: PropTypes.oneOf(['short', 'long']),
}

AvailabilityDates.defaultProps = {
  formatStyle: 'long',
}
