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

import './block-content-preview.css'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Editor, Frame} from '@craftjs/core'
import {components} from '../block-content-editor-components'
import {useGetSerializedNodes} from '../hooks/useGetSerializedNodes'
import {ScaleView} from './ScaleView'
import {useState} from 'react'
import {View} from '@instructure/ui-view'
import {Tabs} from '@instructure/ui-tabs'
import {BlockContentPreviewTabIcon} from './BlockContentPreviewTabIcon'

const I18n = createI18nScope('block_content_editor')

type PreviewMode = 'desktop' | 'tablet' | 'mobile'
const previewSizes: Record<PreviewMode, {containerWidth: number; contentWidth: number}> = {
  desktop: {containerWidth: 900, contentWidth: 1042},
  tablet: {containerWidth: 600, contentWidth: 768},
  mobile: {containerWidth: 375, contentWidth: 375},
}

export const BlockContentPreview = () => {
  const [previewMode, setPreviewMode] = useState<PreviewMode>('desktop')
  const data = useGetSerializedNodes()
  const editor = (
    <Editor enabled={false} resolver={components}>
      <Frame data={data} />
    </Editor>
  )

  const desktopIcon = (
    <BlockContentPreviewTabIcon
      svgPath="/images/block-content-editor/preview_mode_desktop_menu_icon.svg"
      title={I18n.t('Desktop')}
      selected={previewMode === 'desktop'}
    />
  )

  const tabletIcon = (
    <BlockContentPreviewTabIcon
      svgPath="/images/block-content-editor/preview_mode_tablet_menu_icon.svg"
      title={I18n.t('Tablet')}
      selected={previewMode === 'tablet'}
    />
  )

  const mobileIcon = (
    <BlockContentPreviewTabIcon
      svgPath="/images/block-content-editor/preview_mode_mobile_menu_icon.svg"
      title={I18n.t('Mobile')}
      selected={previewMode === 'mobile'}
    />
  )

  return (
    <View
      background="secondary"
      padding="medium large"
      height="100%"
      data-testid="block-content-preview-layout"
      className="block-content-preview-container"
    >
      <Tabs
        padding="0"
        themeOverride={{
          defaultBackground: 'transparent',
        }}
        onRequestTabChange={(_, {id}) => {
          setPreviewMode(id as PreviewMode)
        }}
      >
        <Tabs.Panel id="desktop" isSelected={previewMode === 'desktop'} renderTitle={desktopIcon}>
          <ScaleView {...previewSizes['desktop']}>{editor}</ScaleView>
        </Tabs.Panel>
        <Tabs.Panel id="tablet" isSelected={previewMode === 'tablet'} renderTitle={tabletIcon}>
          <ScaleView {...previewSizes['tablet']}>{editor}</ScaleView>
        </Tabs.Panel>
        <Tabs.Panel id="mobile" isSelected={previewMode === 'mobile'} renderTitle={mobileIcon}>
          <ScaleView {...previewSizes['mobile']}>{editor}</ScaleView>
        </Tabs.Panel>
      </Tabs>
    </View>
  )
}
