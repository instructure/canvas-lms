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

import React from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {ModuleItemContentType} from '../../hooks/queries/useModuleItemContent'

const I18n = createI18nScope('context_modules_v2')

interface AddItemTypeSelectorProps {
  itemType: ModuleItemContentType
  onChange: (value: ModuleItemContentType) => void
}

const AddItemTypeSelector: React.FC<AddItemTypeSelectorProps> = ({itemType, onChange}) => {
  return (
    <SimpleSelect
      renderLabel={I18n.t('Add')}
      value={itemType}
      onChange={(_e, {value}) => onChange(value as ModuleItemContentType)}
    >
      <SimpleSelect.Option id="assignment" value="assignment">
        {I18n.t('Assignment')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="quiz" value="quiz">
        {I18n.t('Quiz')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="file" value="file">
        {I18n.t('File')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="page" value="page">
        {I18n.t('Page')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="discussion" value="discussion">
        {I18n.t('Discussion')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="context_module_sub_header" value="context_module_sub_header">
        {I18n.t('Text Header')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="external_url" value="external_url">
        {I18n.t('External URL')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="external_tool" value="external_tool">
        {I18n.t('External Tool')}
      </SimpleSelect.Option>
    </SimpleSelect>
  )
}

export default AddItemTypeSelector
