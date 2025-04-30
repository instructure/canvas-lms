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

import React, {type ReactElement} from 'react'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('context_modules_v2')

interface IndentSelectorProps {
  value: number
  onChange: (value: number) => void
  label?: string | ReactElement
}

const IndentSelector: React.FC<IndentSelectorProps> = ({value, onChange, label}) => {
  return (
    <SimpleSelect
      renderLabel={label || I18n.t('Indentation')}
      value={value}
      onChange={(_e, {value}) => onChange(value as number)}
    >
      <SimpleSelect.Option id="0" value={0}>
        {I18n.t("Don't indent")}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="1" value={1}>
        {I18n.t('Indent 1 level')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="2" value={2}>
        {I18n.t('Indent 2 levels')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="3" value={3}>
        {I18n.t('Indent 3 levels')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="4" value={4}>
        {I18n.t('Indent 4 levels')}
      </SimpleSelect.Option>
      <SimpleSelect.Option id="5" value={5}>
        {I18n.t('Indent 5 levels')}
      </SimpleSelect.Option>
    </SimpleSelect>
  )
}

export default IndentSelector
