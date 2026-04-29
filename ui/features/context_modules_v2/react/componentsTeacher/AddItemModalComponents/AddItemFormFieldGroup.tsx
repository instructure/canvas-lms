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

import React, {type ReactElement, type ReactNode} from 'react'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {useScope as createI18nScope} from '@canvas/i18n'
import IndentSelector from './IndentSelector'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('context_modules_v2')

export interface AddItemFormFieldGroupData {
  indentValue: number
  onIndentChange: (value: number) => void
  moduleName: string
}

interface AddItemFormFieldGroupProps extends AddItemFormFieldGroupData {
  children: ReactNode
}

const AddItemFormFieldGroup: React.FC<AddItemFormFieldGroupProps> = ({
  children,
  indentValue,
  onIndentChange,
  moduleName,
}) => {
  return (
    <View as="div" margin="small">
      <FormFieldGroup
        description={
          <ScreenReaderContent>
            {I18n.t('Add an item to %{module}', {module: moduleName})}
          </ScreenReaderContent>
        }
        rowSpacing="medium"
        layout="stacked"
        vAlign="top"
        isGroup={false}
        as="form"
      >
        {children}
        <IndentSelector value={indentValue} onChange={onIndentChange} />
      </FormFieldGroup>
    </View>
  )
}

export default AddItemFormFieldGroup
