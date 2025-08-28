/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {View} from '@instructure/ui-view'
import {Checkbox} from '@instructure/ui-checkbox'
import {SettingsIncludeTitleProps} from './types'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block_content_editor')

export const SettingsIncludeTitle = ({checked, onChange}: SettingsIncludeTitleProps) => {
  return (
    <View as="div" margin="medium 0 medium 0">
      <Checkbox
        variant="toggle"
        label={I18n.t('Include block title')}
        checked={checked}
        onChange={onChange}
      />
    </View>
  )
}
