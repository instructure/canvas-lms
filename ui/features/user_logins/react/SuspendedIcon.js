/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import {Tooltip} from '@instructure/ui-tooltip'
import {IconButton} from '@instructure/ui-buttons'
import {IconWarningLine} from '@instructure/ui-icons'

const I18n = useI18nScope('user_name')

export default function SuspendedIcon({login}) {
  const tipText = I18n.t(
    'The login %{login} is currently suspended and will not be able to access Canvas',
    {login}
  )
  return (
    <Tooltip renderTip={tipText} on={['hover', 'focus', 'click']} placement="end">
      <IconButton
        renderIcon={IconWarningLine}
        size="large"
        color="danger"
        withBackground={false}
        withBorder={false}
        screenReaderLabel={I18n.t('Toggle tooltip')}
      />
    </Tooltip>
  )
}
