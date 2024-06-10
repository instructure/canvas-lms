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
import {type FormMessage} from '@instructure/ui-form-field'
import {IconButton} from '@instructure/ui-buttons'
import {NumberInput} from '@instructure/ui-number-input'
import {Popover} from '@instructure/ui-popover'
import {IconTableInsertColumnAfterLine} from '@instructure/ui-icons'
import {View} from '@instructure/ui-view'

const MIN_COLS = 1
const MAX_COLS = 4

type ColumnCountPopupProps = {
  columns: number
}

const ColumnCountPopup = ({columns}: ColumnCountPopupProps) => {
  const {
    actions: {setProp},
    props,
  } = useNode(node => ({
    props: node.data.props,
  }))
  const [userValue, setUserValue] = useState<string>(columns.toString())
  const [cols, setCols] = useState<number>(columns)
  const [messages, setMessages] = useState<FormMessage[]>([])
  const [isShowingContent, setIsShowingContent] = useState(false)

  const handleShowContent = useCallback(() => {
    setIsShowingContent(true)
  }, [])

  const handleHideContent = useCallback(() => {
    setIsShowingContent(false)
  }, [])

  const setColumns = useCallback(
    (value: number) => {
      setCols(value)
      setUserValue(value.toString())
      setProp(prps => (prps.columns = value))
    },
    [setProp]
  )

  const handleChangeColumnns = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>, value: string) => {
      setUserValue(value)
      const cols = parseInt(value, 10)
      setCols(cols)
      if (!Number.isNaN(cols) && cols >= MIN_COLS && cols <= MAX_COLS) {
        setProp(prps => (prps.columns = value))
      } else {
        setMessages([{text: `Columns must be between 1 and ${MAX_COLS}`, type: 'error'}])
      }
    },
    [setProp]
  )

  const handleDecrementCols = useCallback(() => {
    if (Number.isNaN(cols)) return
    if (cols === null) setColumns(MIN_COLS)
    if (cols > MIN_COLS) setColumns(cols - 1)
  }, [cols, setColumns])

  const handleIncrementCols = useCallback(() => {
    if (Number.isNaN(cols)) return
    if (cols < MAX_COLS) setColumns(cols + 1)
  }, [cols, setColumns])

  return (
    <Popover
      renderTrigger={
        <IconButton
          size="small"
          withBackground={false}
          withBorder={false}
          screenReaderLabel="Button Icon"
        >
          <IconTableInsertColumnAfterLine size="x-small" />
        </IconButton>
      }
      isShowingContent={isShowingContent}
      onShowContent={handleShowContent}
      onHideContent={handleHideContent}
      on="click"
      screenReaderLabel="Popover Dialog Example"
      shouldContainFocus={true}
      shouldReturnFocus={true}
      shouldCloseOnDocumentClick={true}
    >
      <View as="div" padding="x-small">
        <NumberInput
          renderLabel={`Columns (1-${MAX_COLS})`}
          isRequired={true}
          messages={messages}
          value={userValue}
          width="15rem"
          onChange={handleChangeColumnns}
          onIncrement={handleIncrementCols}
          onDecrement={handleDecrementCols}
        />
      </View>
    </Popover>
  )
}

export {ColumnCountPopup}
