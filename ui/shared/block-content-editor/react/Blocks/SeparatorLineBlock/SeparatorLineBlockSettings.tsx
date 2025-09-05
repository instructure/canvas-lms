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

import {useNode} from '@craftjs/core'
import {View} from '@instructure/ui-view'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ColorPickerWrapper} from '../BlockItems/ColorPickerWrapper'
import {SeparatorLineBlockProps} from './SeparatorLineBlock'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'
import {BorderWidthValues} from '@instructure/emotion'
import {RadioInput, RadioInputGroup} from '@instructure/ui-radio-input'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('block_content_editor')

const THICKNESS_OPTIONS: {label: string; value: BorderWidthValues}[] = [
  {label: I18n.t('Small'), value: 'small'},
  {label: I18n.t('Medium'), value: 'medium'},
  {label: I18n.t('Large'), value: 'large'},
]

export const SeparatorLineBlockSettings = () => {
  const {
    actions: {setProp},
    separatorColor,
    thickness,
    backgroundColor,
  } = useNode(node => ({
    separatorColor: node.data.props.separatorColor,
    thickness: node.data.props.thickness,
    backgroundColor: node.data.props.backgroundColor,
  }))

  const handleSeparatorColorChange = (value: string) => {
    setProp((props: SeparatorLineBlockProps) => {
      props.separatorColor = value
    })
  }

  const handleBackgroundColorChange = (value: string) => {
    setProp((props: SeparatorLineBlockProps) => {
      props.backgroundColor = value
    })
  }

  const handleThicknessChange = (value: BorderWidthValues) => {
    setProp((props: SeparatorLineBlockProps) => {
      props.thickness = value
    })
  }

  return (
    <View as="div">
      <SettingsSectionToggle
        title={I18n.t('Color settings')}
        collapsedLabel={I18n.t('Expand color settings')}
        expandedLabel={I18n.t('Collapse color settings')}
        defaultExpanded={true}
        includeSeparator={true}
      >
        <ColorPickerWrapper
          label={I18n.t('Background color')}
          value={backgroundColor}
          baseColor={separatorColor}
          onChange={handleBackgroundColorChange}
          baseColorLabel={I18n.t('Separator color')}
        />
      </SettingsSectionToggle>

      <SettingsSectionToggle
        title={I18n.t('Separator settings')}
        collapsedLabel={I18n.t('Expand separator settings')}
        expandedLabel={I18n.t('Collapse separator settings')}
        defaultExpanded={true}
        includeSeparator={false}
      >
        <Flex direction="column" gap="medium">
          <ColorPickerWrapper
            label={I18n.t('Separator color')}
            value={separatorColor}
            baseColor={backgroundColor}
            onChange={handleSeparatorColorChange}
            baseColorLabel={I18n.t('Background color')}
          />

          <RadioInputGroup
            name="separator-line-block-settings-thickness"
            description={I18n.t('Separator size')}
            value={thickness}
            onChange={(_event, value) => handleThicknessChange(value as BorderWidthValues)}
          >
            {THICKNESS_OPTIONS.map(option => (
              <RadioInput key={option.value} label={option.label} value={option.value} />
            ))}
          </RadioInputGroup>
        </Flex>
      </SettingsSectionToggle>
    </View>
  )
}
