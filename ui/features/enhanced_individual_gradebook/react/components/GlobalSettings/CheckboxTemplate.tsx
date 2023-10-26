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

import React from 'react'
import {Checkbox} from '@instructure/ui-checkbox'
import {View} from '@instructure/ui-view'

type Props = {
  checked: boolean
  dataTestId: string
  label: string
  onChange: (event: React.ChangeEvent<HTMLInputElement>) => void
}

export const GlobalSettingsCheckboxTheme = {
  checkedBackground: '#0375ff',
  borderColor: '#777777',
  labelFontSizeSmall: '1rem',
}

export const GlobalSettingsCheckboxViewTheme = {
  backgroundPrimary: '#eee',
  paddingMedium: '16px',
}

export default function CheckboxTemplate({checked, dataTestId, label, onChange}: Props) {
  return (
    <View
      as="div"
      className="checkbox"
      margin="x-small 0"
      borderRadius="medium"
      background="primary"
      padding="medium"
      themeOverride={GlobalSettingsCheckboxViewTheme}
    >
      <Checkbox
        data-testid={dataTestId}
        size="small"
        label={label}
        checked={checked}
        onChange={onChange}
        themeOverride={GlobalSettingsCheckboxTheme}
      />
    </View>
  )
}
