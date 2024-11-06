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

import React, {useCallback, useEffect, useState, useRef} from 'react'
import {useEditor, useNode, type Node} from '@craftjs/core'
import {Flex} from '@instructure/ui-flex'
import {NumberInput} from '@instructure/ui-number-input'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {type ColumnsSectionProps} from './types'
import {GroupBlock} from '../../blocks/GroupBlock'
import {ToolbarColor, type ColorSpec} from '../../common/ToolbarColor'

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('block-editor')

const MIN_COLS = 1
const MAX_COLS = 4

const ColumnsSectionToolbar = () => {
  const {actions, query} = useEditor()
  const {
    actions: {setProp},
    node,
    props,
  } = useNode((n: Node) => ({
    props: n.data.props,
    node: n,
  }))
  const [currColumns, setCurrColumns] = useState(props.columns)
  const colInputRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    if (currColumns !== props.columns) {
      setCurrColumns(props.columns)
      colInputRef.current?.focus()
    }
  }, [currColumns, props.columns])

  const handleDecrementCols = useCallback(() => {
    if (props.columns > MIN_COLS) {
      setProp((prps: ColumnsSectionProps) => (prps.columns = props.columns - 1))
    }
  }, [props.columns, setProp])

  const handleIncrementCols = useCallback(() => {
    if (props.columns < MAX_COLS) {
      setProp((prps: ColumnsSectionProps) => (prps.columns = props.columns + 1))
      const inner = query.node(query.node(node.id).linkedNodes()[0]).get()
      if (inner.data.nodes.length < props.columns + 1) {
        const column = query
          .parseReactElement(<GroupBlock resizable={false} isColumn={true} />)
          .toNodeTree()
        actions.addNodeTree(column, inner.id)
        requestAnimationFrame(() => {
          actions.selectNode(node.id)
        })
      }
    }
  }, [actions, node.id, props.columns, query, setProp])

  const handleChangeColors = useCallback(
    ({bgcolor}: ColorSpec) => {
      setProp((prps: ColumnsSectionProps) => {
        prps.background = bgcolor
      })
    },
    [setProp]
  )

  const getCurrentBackgroundColor = () => {
    return props.background || '#00000000'
  }

  return (
    <Flex gap="small">
      <ToolbarColor bgcolor={getCurrentBackgroundColor()} onChange={handleChangeColors} />
      <Flex gap="x-small">
        <Text>{I18n.t('Section Columns')}</Text>
        <NumberInput
          data-testid="columns-input"
          inputRef={el => {
            colInputRef.current = el
          }}
          renderLabel={
            <ScreenReaderContent>{I18n.t('Columns 1-%{max}', {max: MAX_COLS})}</ScreenReaderContent>
          }
          isRequired={true}
          value={props.columns}
          min={MIN_COLS}
          max={MAX_COLS}
          width="4.5rem"
          onKeyDown={e => {
            e.preventDefault()
          }}
          onIncrement={handleIncrementCols}
          onDecrement={handleDecrementCols}
        />
      </Flex>
    </Flex>
  )
}

export {ColumnsSectionToolbar}
