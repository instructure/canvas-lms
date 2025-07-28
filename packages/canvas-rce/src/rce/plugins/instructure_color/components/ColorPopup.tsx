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
import {Popover} from '@instructure/ui-popover'
import {ColorPicker, type ColorSpec, type TabsSpec} from './ColorPicker'
import formatMessage from '../../../../format-message'

export {type ColorSpec, type TabSpec} from './ColorPicker'

export type ColorPopupProps = {
  tabs: TabsSpec
  open: boolean
  positionTarget?: HTMLElement
  onCancel: () => void
  onChange: (newcolors: ColorSpec) => void
}

const ColorPopup = ({tabs, open, positionTarget, onCancel, onChange}: ColorPopupProps) => {
  const [recreateKey, setRecreateKey] = useState(0)

  const handleHideContent = useCallback(() => {
    onCancel()
    setRecreateKey(Date.now())
  }, [onCancel])

  const handleSubmit = useCallback(
    (newcolors: ColorSpec) => {
      onChange(newcolors)
    },
    [onChange],
  )

  const handleKey = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === 'Escape') {
        onCancel()
      }
    },
    [onCancel],
  )

  return (
    <Popover
      key={recreateKey}
      isShowingContent={open}
      onHideContent={handleHideContent}
      on="click"
      positionTarget={positionTarget}
      screenReaderLabel={formatMessage('Color popup')}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={true}
    >
      {/* eslint-disable-next-line jsx-a11y/no-static-element-interactions */}
      <div onKeyDown={handleKey}>
        <ColorPicker tabs={tabs} onCancel={onCancel} onSave={handleSubmit} />
      </div>
    </Popover>
  )
}

export {ColorPopup}
