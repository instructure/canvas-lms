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

import './block-content-preview-selector-bar.css'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Tabs} from '@instructure/ui-tabs'
import {PreviewMode} from './usePreviewMode'
import {BlockContentPreviewSelectorBarIcon} from './BlockContentPreviewSelectorBarIcon'

const I18n = createI18nScope('block_content_editor')

export const BlockContentPreviewSelectorBar = (props: {
  activeTab: PreviewMode
  onTabChange: (mode: PreviewMode) => void
}) => {
  const desktopIcon = (
    <BlockContentPreviewSelectorBarIcon
      svgPath="/images/block-content-editor/preview_mode_desktop_menu_icon.svg"
      title={I18n.t('Desktop')}
      selected={props.activeTab === 'desktop'}
    />
  )

  const tabletIcon = (
    <BlockContentPreviewSelectorBarIcon
      svgPath="/images/block-content-editor/preview_mode_tablet_menu_icon.svg"
      title={I18n.t('Tablet')}
      selected={props.activeTab === 'tablet'}
    />
  )

  const mobileIcon = (
    <BlockContentPreviewSelectorBarIcon
      svgPath="/images/block-content-editor/preview_mode_mobile_menu_icon.svg"
      title={I18n.t('Mobile')}
      selected={props.activeTab === 'mobile'}
    />
  )

  return (
    <span className="preview-selector-bar-container">
      <Tabs
        padding="0"
        themeOverride={{
          defaultBackground: 'transparent',
        }}
        onRequestTabChange={(_, {id}) => {
          props.onTabChange(id as PreviewMode)
        }}
      >
        <Tabs.Panel
          id="desktop"
          isSelected={props.activeTab === 'desktop'}
          renderTitle={desktopIcon}
        />
        <Tabs.Panel
          id="tablet"
          isSelected={props.activeTab === 'tablet'}
          renderTitle={tabletIcon}
        />
        <Tabs.Panel
          id="mobile"
          isSelected={props.activeTab === 'mobile'}
          renderTitle={mobileIcon}
        />
      </Tabs>
    </span>
  )
}
