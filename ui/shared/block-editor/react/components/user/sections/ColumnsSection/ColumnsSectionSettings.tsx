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
import {NumberInput} from '@instructure/ui-number-input'
import {RadioInputGroup, RadioInput} from '@instructure/ui-radio-input'
import {View} from '@instructure/ui-view'
import {type FormMessage} from '@instructure/ui-form-field'
import {type ColumnSectionVariant} from './ColumnsSection'

const MIN_COLS = 1
const MAX_COLS = 4

const ColumnsSectionSettings = () => {
  const {
    columns,
    variant,
    actions: {setProp},
  } = useNode(node => ({
    columns: node.data.props.columns,
    variant: node.data.props.variant,
  }))
  const [cols, setCols] = useState<number>(columns)
  const [vart, setVart] = useState<ColumnSectionVariant>(variant)
  const [messages, setMessages] = useState<FormMessage[]>([])

  const setColumns = useCallback(
    (value: number) => {
      setCols(value)
      setProp(props => (props.columns = value))
    },
    [setProp]
  )

  const handleChangeColumnns = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>, value: string) => {
      const cols = parseInt(value, 10)
      setCols(cols)
      if (cols >= MIN_COLS && cols <= MAX_COLS) {
        setProp(props => (props.columns = value))
      } else {
        setMessages([{text: `Columns must be between 1 and ${MAX_COLS}`, type: 'error'}])
      }
    },
    [setProp]
  )

  const handleChangeVariant = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>, value: string) => {
      setVart(value as ColumnSectionVariant)
      setProp(props => (props.variant = value))
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
    <div>
      <NumberInput
        renderLabel={`Columns (1-${MAX_COLS})`}
        isRequired={true}
        messages={messages}
        value={cols}
        width="8rem"
        onChange={handleChangeColumnns}
        onIncrement={handleIncrementCols}
        onDecrement={handleDecrementCols}
      />
      <View as="div" margin="small 0 0 0">
        <RadioInputGroup
          description="Column Style"
          name="variant"
          value={vart}
          onChange={handleChangeVariant}
        >
          <RadioInput label="Fixed" value="fixed" />
          <RadioInput label="Fluid" value="fluid" />
        </RadioInputGroup>
      </View>
    </div>
  )
}

export {ColumnsSectionSettings}
