/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useState} from 'react'
import {useEditor} from '@craftjs/core'
import {IconButton} from '@instructure/ui-buttons'
import {Popover} from '@instructure/ui-popover'
import {IconBackgroundColor} from '../../../assets/internal-icons'
import {ColorPicker, type ColorSpec, type TabsSpec} from '@instructure/canvas-rce'
import {getColorsInUse, type ColorsInUse} from '../../../utils'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

type ToolbarColorProps = {
  tabs: TabsSpec
  onChange: (newcolors: ColorSpec) => void
}

const ToolbarColor = ({tabs, onChange}: ToolbarColorProps) => {
  const {query} = useEditor()
  const [isShowingContent, setIsShowingContent] = useState(false)
  const [colorsInUse, setColorsInUse] = useState<ColorsInUse>(getColorsInUse(query))

  const handleShowContent = useCallback(() => {
    setColorsInUse(getColorsInUse(query))
    setIsShowingContent(true)
  }, [query])

  const handleCancel = useCallback(() => {
    setIsShowingContent(false)
  }, [])

  const handleSubmit = useCallback(
    (newcolors: ColorSpec) => {
      setIsShowingContent(false)
      onChange(newcolors)
    },
    [onChange],
  )

  const handleKey = useCallback((e: React.KeyboardEvent) => {
    // capture the arrow keys so they change tabs in the ColorPicker and don't
    // change focus to the next element in the toolbar
    if (['ArrowDown', 'ArrowRight', 'ArrowUp', 'ArrowLeft'].includes(e.key)) {
      e.stopPropagation()
    }
  }, [])

  return (
    <Popover
      renderTrigger={
        <IconButton
          color="secondary"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Color')}
          title={I18n.t('Color')}
        >
          <IconBackgroundColor size="x-small" />
        </IconButton>
      }
      isShowingContent={isShowingContent}
      onShowContent={handleShowContent}
      onHideContent={handleCancel}
      on="click"
      screenReaderLabel={I18n.t('Color popup')}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={true}
    >
      {/* eslint-disable-next-line jsx-a11y/no-static-element-interactions */}
      <div style={{maxHeight: '80vh', overflowY: 'auto'}} onKeyDown={handleKey}>
        <ColorPicker
          tabs={tabs}
          colorsInUse={colorsInUse}
          onCancel={handleCancel}
          onSave={handleSubmit}
        />
      </div>
    </Popover>
  )
}

export {ToolbarColor, type ColorSpec, type ToolbarColorProps}
