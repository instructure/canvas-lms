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
import {useNode} from '@craftjs/core'
import {IconButton} from '@instructure/ui-buttons'
import {RangeInput} from '@instructure/ui-range-input'
import {Popover} from '@instructure/ui-popover'
import {IconTableInsertColumnAfterLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'
import {type ColumnsSectionProps} from './types'

import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('block-editor')

const MIN_COLS = 1
const MAX_COLS = 4

type ColumnCountPopupProps = {
  columns: number
}

const ColumnCountPopup = ({columns}: ColumnCountPopupProps) => {
  const {
    actions: {setProp},
  } = useNode()
  const [cols, setCols] = useState<number>(columns)
  const [isShowingContent, setIsShowingContent] = useState(false)

  const handleShowContent = useCallback(() => {
    setIsShowingContent(true)
  }, [])

  const handleHideContent = useCallback(() => {
    setIsShowingContent(false)
  }, [])

  const handleChangeColumnns = useCallback(
    (value: number | string) => {
      const ncols = Number(value)
      setCols(ncols)
      setProp((prps: ColumnsSectionProps) => (prps.columns = ncols))
    },
    [setProp],
  )

  return (
    <Popover
      renderTrigger={
        <IconButton
          size="small"
          withBackground={false}
          withBorder={false}
          screenReaderLabel={I18n.t('Columns')}
          title={I18n.t('Columns')}
        >
          <IconTableInsertColumnAfterLine size="x-small" />
        </IconButton>
      }
      isShowingContent={isShowingContent}
      onShowContent={handleShowContent}
      onHideContent={handleHideContent}
      on="click"
      screenReaderLabel={I18n.t('Set the number of columns')}
      shouldContainFocus={true}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={true}
    >
      <View as="div" padding="x-small">
        <RangeInput
          label={I18n.t('Columns 1-%{max}', {max: MAX_COLS})}
          size="medium"
          thumbVariant="accessible"
          value={cols}
          min={MIN_COLS}
          max={MAX_COLS}
          onChange={handleChangeColumnns}
        />
      </View>
    </Popover>
  )
}

export {ColumnCountPopup}
