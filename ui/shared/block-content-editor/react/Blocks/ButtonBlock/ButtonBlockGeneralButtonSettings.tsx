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
import {Flex} from '@instructure/ui-flex'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {Checkbox} from '@instructure/ui-checkbox'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ButtonAlignment, ButtonLayout, ButtonBlockGeneralButtonSettingsProps} from './types'

const I18n = createI18nScope('block_content_editor')

const ALIGNMENT_OPTIONS: {label: string; value: ButtonAlignment}[] = [
  {label: I18n.t('Left aligned'), value: 'left'},
  {label: I18n.t('Middle aligned'), value: 'center'},
  {label: I18n.t('Right aligned'), value: 'right'},
]

const LAYOUT_OPTIONS: {label: string; value: ButtonLayout}[] = [
  {label: I18n.t('Horizontal'), value: 'horizontal'},
  {label: I18n.t('Vertical'), value: 'vertical'},
]

export const ButtonBlockGeneralButtonSettings = ({
  alignment,
  layout,
  isFullWidth,
  onAlignmentChange,
  onLayoutChange,
  onIsFullWidthChange,
}: ButtonBlockGeneralButtonSettingsProps) => {
  return (
    <Flex direction="column" gap="medium">
      <Checkbox
        variant="toggle"
        label={I18n.t('Full width buttons')}
        checked={isFullWidth}
        onChange={() => onIsFullWidthChange(!isFullWidth)}
      />

      {!isFullWidth && (
        <RadioInputGroup
          name="button-block-general-button-settings-alignment"
          description={I18n.t('Alignment')}
          value={alignment}
          onChange={(_event, value) => onAlignmentChange(value as ButtonAlignment)}
        >
          {ALIGNMENT_OPTIONS.map(option => (
            <RadioInput key={option.value} label={option.label} value={option.value} />
          ))}
        </RadioInputGroup>
      )}

      <RadioInputGroup
        name="button-block-general-button-settings-layout"
        description={I18n.t('Button layout')}
        value={layout}
        onChange={(_event, value) => onLayoutChange(value as ButtonLayout)}
      >
        {LAYOUT_OPTIONS.map(option => (
          <RadioInput key={option.value} label={option.label} value={option.value} />
        ))}
      </RadioInputGroup>
    </Flex>
  )
}
