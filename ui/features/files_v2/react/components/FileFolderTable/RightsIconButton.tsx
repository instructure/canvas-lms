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
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconButton} from '@instructure/ui-buttons'
import {IconFilesCreativeCommonsLine} from '@instructure/ui-icons'

const I18n = createI18nScope('files_v2')

const RightsIconButton = () => {
  return (
    <IconButton
      withBackground={false}
      withBorder={false}
      size="small"
      shape="circle"
      screenReaderLabel={I18n.t('Rights')}
    >
      <IconFilesCreativeCommonsLine />
    </IconButton>
  )
}

export default RightsIconButton
