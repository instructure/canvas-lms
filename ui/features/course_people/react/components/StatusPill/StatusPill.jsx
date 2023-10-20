/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {string} from 'prop-types'
import {Pill} from '@instructure/ui-pill'
import {Tooltip} from '@instructure/ui-tooltip'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('course_people')

// Value returned from GraphQL
export const ACTIVE_STATE = 'active'
export const INACTIVE_STATE = 'inactive'
export const PENDING_STATE = 'invited'

// Value that should be presented to user
export const PILL_MAP = {
  [INACTIVE_STATE]: {
    text: I18n.t('inactive'),
    hintText: I18n.t('This user is currently not able to access the course'),
    color: 'primary',
  },
  [PENDING_STATE]: {
    text: I18n.t('pending'),
    hintText: I18n.t('This user has not yet accepted the invitation to the course'),
    color: 'info',
  },
}

const StatusPill = ({state}) => {
  if (!PILL_MAP.hasOwnProperty(state)) return null

  const {text, hintText, color} = PILL_MAP[state]

  return (
    <Tooltip as="span" renderTip={hintText}>
      <Pill color={color} margin="0 0 xx-small 0">
        {text}
      </Pill>
    </Tooltip>
  )
}

StatusPill.propTypes = {
  state: string.isRequired,
}

StatusPill.defaultProps = {}

export default StatusPill
