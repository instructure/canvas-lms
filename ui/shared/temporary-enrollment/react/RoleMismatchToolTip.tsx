/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import {Text} from '@instructure/ui-text'

const I18n = useI18nScope('temporary_enrollment')

export default function RoleMismatchToolTip() {
  const tipText = (
    <>
      <Text>{I18n.t('Enrolling the recipient in these courses')}</Text>
      <br />
      <Text>{I18n.t('will grant them different permissions')}</Text>
      <br />
      <Text>{I18n.t('from the provider of the enrollments')}</Text>
    </>
  )

  const tipTriggers: Array<'click' | 'hover' | 'focus'> = ['click', 'hover', 'focus']
  const renderToolTip = () => {
    return (
      <Tooltip renderTip={tipText} on={tipTriggers} placement="top">
        <IconButton
          renderIcon={IconWarningLine}
          size="medium"
          margin="none"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Toggle tooltip')}
        />
      </Tooltip>
    )
  }

  return renderToolTip()
}
