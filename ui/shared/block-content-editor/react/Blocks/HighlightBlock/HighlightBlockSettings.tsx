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
import {useScope as createI18nScope} from '@canvas/i18n'
import {type HighlightBlockProps} from './HighlightBlock'
import {Checkbox} from '@instructure/ui-checkbox'
import {ColorPickerWrapper} from '../BlockItems/ColorPickerWrapper'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {defaultProps} from './defaultProps'

const I18n = createI18nScope('block_content_editor')

export const HighlightBlockSettings = () => {
  const {
    actions: {setProp},
    backgroundColor,
    highlightColor,
    textColor,
    displayIcon,
  } = useNode(node => ({
    ...defaultProps,
    ...node.data.props,
  }))

  return (
    <View as="div">
      <SettingsSectionToggle
        title={I18n.t('Color settings')}
        defaultExpanded={true}
        includeSeparator={true}
      >
        <ColorPickerWrapper
          label={I18n.t('Background color')}
          popoverButtonScreenReaderLabel={I18n.t('Open background color picker popover')}
          value={backgroundColor}
          baseColor={highlightColor}
          baseColorLabel={I18n.t('Highlight color')}
          onChange={color =>
            setProp((props: HighlightBlockProps) => {
              props.backgroundColor = color
            })
          }
        />
      </SettingsSectionToggle>
      <SettingsSectionToggle
        title={I18n.t('Highlight settings')}
        defaultExpanded={true}
        includeSeparator={false}
      >
        <Flex direction="column" gap="medium">
          <Checkbox
            label={I18n.t('Display icon')}
            variant="toggle"
            checked={displayIcon === 'warning'}
            onChange={e =>
              setProp((props: HighlightBlockProps) => {
                props.displayIcon = e.target.checked ? 'warning' : null
              })
            }
          />
          <ColorPickerWrapper
            label={I18n.t('Highlight color')}
            popoverButtonScreenReaderLabel={I18n.t('Open highlight color picker popover')}
            value={highlightColor}
            baseColor={textColor}
            baseColorLabel={I18n.t('Text color')}
            onChange={color =>
              setProp((props: HighlightBlockProps) => {
                props.highlightColor = color
              })
            }
          />
          <ColorPickerWrapper
            label={I18n.t('Text color')}
            popoverButtonScreenReaderLabel={I18n.t('Open text color picker popover')}
            value={textColor}
            baseColor={highlightColor}
            baseColorLabel={I18n.t('Highlight color')}
            onChange={color =>
              setProp((props: HighlightBlockProps) => {
                props.textColor = color
              })
            }
          />
        </Flex>
      </SettingsSectionToggle>
    </View>
  )
}
