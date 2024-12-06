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
import {ColorPicker, type ColorSpec, type TabSpec} from '@instructure/canvas-rce'
import {getColorsInUse, type ColorsInUse} from '../../../utils'

import {useScope} from '@canvas/i18n'

const I18n = useScope('block-editor')

type ToolbarColorProps = {
  tabs: TabSpec
  onChange: (newcolors: ColorSpec) => void
}

const ToolbarColor = ({tabs, onChange}: ToolbarColorProps) => {
  const {query} = useEditor()
  const [isShowingContent, setIsShowingContent] = useState(false)
  const [recreateKey, setRecreateKey] = useState(0)
  const [colorsInUse, setColorsInUse] = useState<ColorsInUse>(getColorsInUse(query))

  const handleShowContent = useCallback(() => {
    setColorsInUse(getColorsInUse(query))
    setIsShowingContent(true)
  }, [query])

  const handleCancel = useCallback(() => {
    setIsShowingContent(false)
    setRecreateKey(Date.now())
  }, [])

  const handleSubmit = useCallback(
    (newcolors: ColorSpec) => {
      setIsShowingContent(false)
      onChange(newcolors)
    },
    [onChange]
  )

  return (
    <Popover
      key={recreateKey}
      renderTrigger={
        <IconButton
          color="secondary"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Color')}
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
      <ColorPicker
        tabs={tabs}
        // @ts-ignore
        colorsInUse={colorsInUse}
        onCancel={handleCancel}
        onSave={handleSubmit}
      />
    </Popover>
  )
}

export {ToolbarColor, type ColorSpec, type ToolbarColorProps}
