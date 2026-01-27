/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import React, {useRef, useCallback} from 'react'
import {Table as InstUITable} from '@instructure/ui-table'
import {View} from '@instructure/ui-view'
import {DragDropContext} from 'react-dnd'
import ReactDnDHTML5Backend from 'react-dnd-html5-backend'
import DragDropWrapper from '../grid/DragDropWrapper'
import {DragDropContainer} from './DragDropContainer'
import {Responsive} from '@instructure/ui-responsive'
import {Cell} from './Cell'
import {Row} from './Row'
import {ColHeader, ColHeaderProps} from './ColHeader'
import {Column} from './utils'
import {RowHeader} from './RowHeader'

interface DragDropConfig {
  type: string
  onMove: (draggedId: string | number, hoverIndex: number) => void
  onDragEnd?: () => void
  onDragLeave?: () => void
  enabled?: boolean
}

interface TableProps {
  id?: string
  caption?: string
  columns: Array<Column>
  data: Array<Record<string, any>>
  renderAboveHeader?: (
    columns: Array<Column>,
    handleKeyDown: (event: React.KeyboardEvent, rowIndex: number, colIndex: number) => void,
  ) => React.ReactNode
  dragDropConfig?: DragDropConfig
}

const TableComponent: React.FC<TableProps> = ({
  id,
  columns,
  data,
  caption,
  renderAboveHeader,
  dragDropConfig,
}) => {
  const tableRef = useRef<HTMLDivElement>(null)

  const getCellElement = useCallback((rowIndex: number, colIndex: number): HTMLElement | null => {
    if (!tableRef.current) return null
    let cellId: string
    if (rowIndex === -1) {
      cellId = `header-${colIndex}`
    } else {
      cellId = `cell-${rowIndex}-${colIndex}`
    }
    return tableRef.current.querySelector(`[data-cell-id="${cellId}"]`)
  }, [])

  const focusCell = useCallback(
    (rowIndex: number, colIndex: number) => {
      const cell = getCellElement(rowIndex, colIndex)
      if (cell) {
        cell.focus()
      }
    },
    [getCellElement],
  )

  const handleKeyDown = useCallback(
    (event: React.KeyboardEvent, rowIndex: number, colIndex: number) => {
      const {key} = event
      let newRowIndex = rowIndex
      let newColIndex = colIndex

      switch (key) {
        case 'ArrowUp': {
          event.preventDefault()
          // Allow moving from data (0+) to header (-1) to above-header (-2)
          // Above-header row exists only if renderAboveHeader is provided
          const minRow = renderAboveHeader ? -2 : -1
          newRowIndex = Math.max(minRow, rowIndex - 1)
          break
        }
        case 'ArrowDown':
          event.preventDefault()
          // Allow moving from above-header (-2) to header (-1) to data rows (0+)
          newRowIndex = Math.min(data.length - 1, rowIndex + 1)
          break
        case 'ArrowLeft':
          event.preventDefault()
          newColIndex = Math.max(0, colIndex - 1)
          break
        case 'ArrowRight':
          event.preventDefault()
          newColIndex = Math.min(columns.length - 1, colIndex + 1)
          break
        default:
          return
      }

      if (newRowIndex !== rowIndex || newColIndex !== colIndex) {
        focusCell(newRowIndex, newColIndex)
      }
    },
    [data.length, columns.length, focusCell, renderAboveHeader],
  )

  const renderColHeader = useCallback(
    (col: Column, colIndex: number, dragDropConfig?: DragDropConfig) => {
      const colHeaderProps: ColHeaderProps = {
        id: col.key,
        width: col.width,
        isSticky: col.isSticky,
        'data-cell-id': `header-${colIndex}`,
        tabIndex: 0,
        onKeyDown: (e: React.KeyboardEvent) => handleKeyDown(e, -1, colIndex),
        ...col.colHeaderProps,
      }

      return col.draggable && dragDropConfig ? (
        <DragDropWrapper
          key={col.key}
          component={ColHeader}
          type={dragDropConfig.type}
          itemId={col.key}
          index={colIndex}
          onMove={dragDropConfig.onMove}
          onDragEnd={dragDropConfig.onDragEnd}
          {...colHeaderProps}
        >
          {typeof col.header === 'function' ? col.header() : col.header}
        </DragDropWrapper>
      ) : (
        <ColHeader key={col.key} {...colHeaderProps}>
          {typeof col.header === 'function' ? col.header() : col.header}
        </ColHeader>
      )
    },
    [handleKeyDown],
  )

  const renderHeader = () => {
    const isDragDropEnabled = dragDropConfig?.enabled

    if (isDragDropEnabled && dragDropConfig) {
      return (
        <InstUITable.Head>
          <>
            {renderAboveHeader && renderAboveHeader(columns, handleKeyDown)}
            <DragDropContainer type={dragDropConfig.type} onDragLeave={dragDropConfig.onDragLeave}>
              {connectDropTarget => (
                <Row
                  setRef={el => {
                    if (el instanceof HTMLElement) {
                      connectDropTarget(el)
                    }
                  }}
                >
                  {columns.map((col, colIndex) => renderColHeader(col, colIndex, dragDropConfig))}
                </Row>
              )}
            </DragDropContainer>
          </>
        </InstUITable.Head>
      )
    }

    return (
      <InstUITable.Head>
        <>
          {renderAboveHeader && renderAboveHeader(columns, handleKeyDown)}
          <Row>{columns.map((col, colIndex) => renderColHeader(col, colIndex))}</Row>
        </>
      </InstUITable.Head>
    )
  }

  const renderBody = () => {
    return (
      <InstUITable.Body>
        {data.map((row, rowIndex) => (
          <Row key={rowIndex}>
            {columns.map((col, colIndex) => {
              const props = {
                id: `${rowIndex}-${col.key}`,
                'data-cell-id': `cell-${rowIndex}-${colIndex}`,
                tabIndex: 0,
                onKeyDown: (e: React.KeyboardEvent) => handleKeyDown(e, rowIndex, colIndex),
                isSticky: col.isSticky,
                ...col.cellProps,
              }

              if (col.isRowHeader) {
                return (
                  <RowHeader key={col.key} {...props}>
                    {col.render ? col.render(row[col.key], row) : row[col.key]}
                  </RowHeader>
                )
              }

              if (col.render) {
                return (
                  <Cell key={col.key} {...props}>
                    {(focused: boolean) => col.render!(row[col.key], row, focused)}
                  </Cell>
                )
              }

              return (
                <Cell key={col.key} {...props}>
                  {row[col.key]}
                </Cell>
              )
            })}
          </Row>
        ))}
      </InstUITable.Body>
    )
  }

  return (
    <Responsive
      query={{
        small: {maxWidth: '40rem'},
        large: {minWidth: '41rem'},
      }}
      props={{
        small: {layout: 'stacked'},
        large: {layout: 'auto'},
      }}
    >
      {props => (
        <View
          as="div"
          overflowX="auto"
          elementRef={(el: Element | null) => {
            if (el instanceof HTMLDivElement) {
              ;(tableRef as React.MutableRefObject<HTMLDivElement | null>).current = el
            }
          }}
        >
          <InstUITable id={id} caption={caption} {...props}>
            {renderHeader()}
            {renderBody()}
          </InstUITable>
        </View>
      )}
    </Responsive>
  )
}

export const Table = DragDropContext(ReactDnDHTML5Backend)(
  TableComponent,
) as React.ComponentType<TableProps>
