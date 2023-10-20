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
import {IconButton} from '@instructure/ui-buttons'
import {IconMoreLine} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import {string} from 'prop-types'

const I18n = useI18nScope('course_people')

const RosterTableRowMenuButton = ({name}) => {
  return (
    <IconButton
      renderIcon={<IconMoreLine />}
      screenReaderLabel={I18n.t('Manage %{user_name}', {user_name: name})}
      withBorder={false}
      withBackground={false}
    />
  )
}

RosterTableRowMenuButton.propTypes = {
  name: string.isRequired,
}

RosterTableRowMenuButton.defaultProps = {}

export default RosterTableRowMenuButton
