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
import {useNode} from '@craftjs/core'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ButtonBlockIndividualButtonSettings} from './ButtonBlockIndividualButtonSettings'
import {ButtonBlockGeneralButtonSettings} from './ButtonBlockGeneralButtonSettings'
import {ButtonBlockColorSettings} from './ButtonBlockColorSettings'
import {ButtonBlockProps, ButtonData, ButtonAlignment, ButtonLayout} from './types'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'
import {SettingsIncludeTitle} from '../BlockItems/SettingsIncludeTitle/SettingsIncludeTitle'

const I18n = createI18nScope('block_content_editor')

export const ButtonBlockSettings = () => {
  const {
    actions: {setProp},
    includeBlockTitle,
    backgroundColor,
    textColor,
    alignment,
    layout,
    isFullWidth,
    buttons,
  } = useNode(node => ({
    includeBlockTitle: node.data.props.includeBlockTitle,
    backgroundColor: node.data.props.backgroundColor,
    textColor: node.data.props.textColor,
    alignment: node.data.props.alignment,
    layout: node.data.props.layout,
    isFullWidth: node.data.props.isFullWidth,
    buttons: node.data.props.buttons,
  }))

  const handleIncludeBlockTitleChange = () => {
    setProp((props: ButtonBlockProps) => {
      props.includeBlockTitle = !includeBlockTitle
    })
  }

  const handleBackgroundColorChange = (color: string) => {
    setProp((props: ButtonBlockProps) => {
      props.backgroundColor = color
    })
  }

  const handleTextColorChange = (color: string) => {
    setProp((props: ButtonBlockProps) => {
      props.textColor = color
    })
  }

  const handleAlignmentChange = (alignment: ButtonAlignment) => {
    setProp((props: ButtonBlockProps) => {
      props.alignment = alignment
    })
  }

  const handleLayoutChange = (layout: ButtonLayout) => {
    setProp((props: ButtonBlockProps) => {
      props.layout = layout
    })
  }

  const handleIsFullWidthChange = (isFullWidth: boolean) => {
    setProp((props: ButtonBlockProps) => {
      props.isFullWidth = isFullWidth
    })
  }

  const handleButtonsChange = (buttons: ButtonData[]) => {
    setProp((props: ButtonBlockProps) => {
      props.buttons = buttons
    })
  }

  return (
    <View as="div">
      <SettingsIncludeTitle checked={includeBlockTitle} onChange={handleIncludeBlockTitleChange} />
      <SettingsSectionToggle
        title={I18n.t('Color settings')}
        collapsedLabel={I18n.t('Expand color settings')}
        expandedLabel={I18n.t('Collapse color settings')}
        defaultExpanded={false}
        includeSeparator={true}
      >
        <ButtonBlockColorSettings
          includeBlockTitle={includeBlockTitle}
          backgroundColor={backgroundColor}
          textColor={textColor}
          onBackgroundColorChange={handleBackgroundColorChange}
          onTextColorChange={handleTextColorChange}
        />
      </SettingsSectionToggle>

      <SettingsSectionToggle
        title={I18n.t('General button settings')}
        collapsedLabel={I18n.t('Expand general button settings')}
        expandedLabel={I18n.t('Collapse general button settings')}
        defaultExpanded={true}
        includeSeparator={true}
      >
        <ButtonBlockGeneralButtonSettings
          alignment={alignment}
          layout={layout}
          isFullWidth={isFullWidth}
          onAlignmentChange={handleAlignmentChange}
          onLayoutChange={handleLayoutChange}
          onIsFullWidthChange={handleIsFullWidthChange}
        />
      </SettingsSectionToggle>

      <SettingsSectionToggle
        title={I18n.t('Individual button settings')}
        collapsedLabel={I18n.t('Expand individual button settings')}
        expandedLabel={I18n.t('Collapse individual button settings')}
        defaultExpanded={true}
        includeSeparator={false}
      >
        <ButtonBlockIndividualButtonSettings
          backgroundColor={backgroundColor}
          initialButtons={buttons}
          onButtonsChange={handleButtonsChange}
        />
      </SettingsSectionToggle>
    </View>
  )
}
