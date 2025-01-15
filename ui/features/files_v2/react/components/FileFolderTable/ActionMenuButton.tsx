/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {CondensedButton, IconButton} from '@instructure/ui-buttons'
import {IconMoreLine, IconArrowOpenDownLine} from '@instructure/ui-icons'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('files_v2')

interface ActionMenuButtonProps {
  isStacked: boolean
}
const ActionMenuButton = ({isStacked}: ActionMenuButtonProps) => {
  const actionLabel = I18n.t('Actions')

  return isStacked ? (
    <CondensedButton renderIcon={<IconArrowOpenDownLine />}>{actionLabel}</CondensedButton>
  ) : (
    <IconButton
      renderIcon={IconMoreLine}
      withBackground={false}
      withBorder={false}
      screenReaderLabel={actionLabel}
    />
  )
}

export default ActionMenuButton
