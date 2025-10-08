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
import {ButtonBlockProps, ButtonAlignment, ButtonLayout} from './types'
import {ButtonData} from '../BlockItems/Button/types'
import {SettingsSectionToggle} from '../BlockItems/SettingsSectionToggle/SettingsSectionToggle'
import {SettingsIncludeTitle} from '../BlockItems/SettingsIncludeTitle/SettingsIncludeTitle'
import {defaultProps} from './defaultProps'

const I18n = createI18nScope('block_content_editor')

export const ButtonBlockSettings = () => {
  const {
    actions: {setProp},
    includeBlockTitle,
    backgroundColor,
    titleColor,
    alignment,
    layout,
    isFullWidth,
    buttons,
  } = useNode(node => ({
    ...defaultProps,
    ...node.data.props,
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

  const handleTitleColorChange = (color: string) => {
    setProp((props: ButtonBlockProps) => {
      props.titleColor = color
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
        defaultExpanded={true}
        includeSeparator={true}
      >
        <ButtonBlockColorSettings
          includeBlockTitle={includeBlockTitle}
          backgroundColor={backgroundColor}
          titleColor={titleColor}
          onBackgroundColorChange={handleBackgroundColorChange}
          onTitleColorChange={handleTitleColorChange}
        />
      </SettingsSectionToggle>

      <SettingsSectionToggle
        title={I18n.t('General button settings')}
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
