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
import I18n from 'i18n!assignments_2'
import React from 'react'
import PropTypes from 'prop-types'

import FriendlyDatetime from '../../shared/FriendlyDatetime'

function AvailabilityDates(props) {
  const {assignment, formatStyle} = props
  const longFmt = formatStyle === 'long'

  if (assignment.lockAt && assignment.unlockAt) {
    return (
      <React.Fragment>
        <FriendlyDatetime
          prefix={longFmt ? I18n.t('Available') : ''}
          dateTime={assignment.unlockAt}
          format={longFmt ? I18n.t('#date.formats.full') : I18n.t('#date.formats.short')}
        />
        <FriendlyDatetime
          prefix={longFmt ? I18n.t(' until') : I18n.t(' to')}
          dateTime={assignment.lockAt}
          format={I18n.t('#date.formats.full')}
        />
      </React.Fragment>
    )
  } else if (assignment.lockAt) {
    return (
      <FriendlyDatetime
        prefix={I18n.t('Available until')}
        dateTime={assignment.lockAt}
        format={I18n.t('#date.formats.full')}
      />
    )
  } else if (assignment.unlockAt) {
    return (
      <FriendlyDatetime
        prefix={I18n.t('Available after')}
        dateTime={assignment.unlockAt}
        format={I18n.t('#date.formats.full')}
      />
    )
  } else {
    return null
  }
}

AvailabilityDates.propTypes = {
  assignment: PropTypes.shape({
    lockAt: PropTypes.string,
    unlockAt: PropTypes.string
  }).isRequired,
  formatStyle: PropTypes.oneOf(['short', 'long'])
}

AvailabilityDates.defaultProps = {
  formatStyle: 'long'
}

export default React.memo(AvailabilityDates)
