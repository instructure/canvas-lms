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

import React, {useMemo, useCallback, useState, useRef} from 'react'
import {flushSync} from 'react-dom'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import {IconAddLine} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import type {Widget, WidgetConfig} from '../types'
import {getWidget} from './WidgetRegistry'
import {useResponsiveContext} from '../hooks/useResponsiveContext'
import {useWidgetLayout} from '../hooks/useWidgetLayout'
import {Flex} from '@instructure/ui-flex'
import {DragDropContext, Droppable, Draggable, type DropResult} from 'react-beautiful-dnd'
import AddWidgetModal from './AddWidgetModal/AddWidgetModal'

const I18n = createI18nScope('widget_dashboard')

const widgetsAsColumns = (widgets: Widget[]): Widget[][] => {
  const inColumns = widgets.reduce(
    (acc, val) => {
      const column = val.position.col || 1
      acc[column - 1].push(val)
      return acc
    },
    [[] as Widget[], [] as Widget[]] as Widget[][],
  )

  inColumns.forEach((column, idx) => {
    inColumns[idx] = column.sort((a, b) => a.position.row - b.position.row)
  })

  return inColumns
}

interface WidgetGridProps {
  config: WidgetConfig
  isEditMode?: boolean
}

const WidgetGrid: React.FC<WidgetGridProps> = ({config, isEditMode = false}) => {
  const {matches} = useResponsiveContext()
  const {moveWidgetToPosition} = useWidgetLayout()
  const widgetsByColumn = useMemo(() => widgetsAsColumns(config.widgets), [config.widgets])
  const [addModalOpen, setAddModalOpen] = useState(false)
  const [addPosition, setAddPosition] = useState<{col: number; row: number} | null>(null)
  const lastDraggedWidgetIdRef = useRef<string | null>(null)

  const handleDragEnd = useCallback(
    (result: DropResult) => {
      if (!result.destination) return

      const sourceCol = parseInt(result.source.droppableId.replace('column-', ''), 10)
      const destCol = parseInt(result.destination.droppableId.replace('column-', ''), 10)
      const destIndex = result.destination.index

      const destColWidgets = config.widgets
        .filter(w => w.position.col === destCol && w.id !== result.draggableId)
        .sort((a, b) => a.position.row - b.position.row)

      const targetRow =
        destIndex < destColWidgets.length
          ? destColWidgets[destIndex].position.row
          : destColWidgets.length > 0
            ? Math.max(...destColWidgets.map(w => w.position.row)) + 1
            : 1

      lastDraggedWidgetIdRef.current = result.draggableId

      flushSync(() => {
        moveWidgetToPosition(result.draggableId, destCol, targetRow)
      })

      const dragHandle = document.querySelector(
        `[data-testid="${lastDraggedWidgetIdRef.current}-drag-handle"]`,
      ) as HTMLElement
      if (dragHandle) {
        dragHandle.focus()
      }
      lastDraggedWidgetIdRef.current = null
    },
    [moveWidgetToPosition, config.widgets],
  )

  const renderWidget = (widget: Widget, dragHandleProps?: any) => {
    const widgetRenderer = getWidget(widget.type)

    if (!widgetRenderer) {
      return (
        <Text color="danger">{I18n.t('Unknown widget type: %{type}', {type: widget.type})}</Text>
      )
    }

    const WidgetComponent = widgetRenderer.component
    return (
      <WidgetComponent widget={widget} isEditMode={isEditMode} dragHandleProps={dragHandleProps} />
    )
  }

  const renderAddWidgetPlaceholder = (col: number, row: number) => {
    if (!isEditMode) return null

    return (
      <Button
        onClick={() => {
          setAddPosition({col, row})
          setAddModalOpen(true)
        }}
        display="block"
        textAlign="center"
        withBackground={false}
        color="primary"
        margin="x-small 0"
        themeOverride={{
          borderStyle: 'dashed',
        }}
      >
        <Flex direction="row" justifyItems="center" alignItems="center" gap="x-small">
          <Flex.Item>
            <IconAddLine />
          </Flex.Item>
          <Flex.Item>
            <Text size="small">{I18n.t('Add widget')}</Text>
          </Flex.Item>
        </Flex>
      </Button>
    )
  }

  const renderWidgetInView = (widget: Widget, key?: string) => (
    <Flex.Item key={key || widget.id} data-testid={`widget-container-${widget.id}`}>
      {renderWidget(widget)}
    </Flex.Item>
  )

  const renderDesktopGrid = () => {
    return (
      <DragDropContext onDragEnd={handleDragEnd}>
        <Flex data-testid="widget-columns" direction="row" gap="x-small" alignItems="start">
          <Flex.Item shouldGrow shouldShrink width="66%">
            {isEditMode ? (
              <Droppable droppableId="column-1">
                {(provided, snapshot) => (
                  <div
                    ref={provided.innerRef}
                    {...provided.droppableProps}
                    style={{minHeight: '100px'}}
                  >
                    <Flex
                      direction="column"
                      gap="x-small"
                      data-testid="widget-column-1"
                      width="100%"
                    >
                      {renderAddWidgetPlaceholder(1, 1)}
                      {widgetsByColumn[0].map((widget, index) => (
                        <React.Fragment key={widget.id}>
                          <Draggable draggableId={widget.id} index={index}>
                            {provided => (
                              <div
                                ref={provided.innerRef}
                                {...provided.draggableProps}
                                data-testid={`widget-container-${widget.id}`}
                              >
                                {renderWidget(widget, provided.dragHandleProps)}
                              </div>
                            )}
                          </Draggable>
                          {renderAddWidgetPlaceholder(1, widget.position.row + 1)}
                        </React.Fragment>
                      ))}
                      {provided.placeholder}
                    </Flex>
                  </div>
                )}
              </Droppable>
            ) : (
              <Flex direction="column" gap="x-small" data-testid="widget-column-1" width="100%">
                {widgetsByColumn[0].map(widget => (
                  <Flex.Item key={widget.id} data-testid={`widget-container-${widget.id}`}>
                    {renderWidget(widget)}
                  </Flex.Item>
                ))}
                {/* Ensure Flex renders even when empty */}
                {null}
              </Flex>
            )}
          </Flex.Item>
          <Flex.Item shouldGrow shouldShrink width="33%">
            {isEditMode ? (
              <Droppable droppableId="column-2">
                {(provided, snapshot) => (
                  <div
                    ref={provided.innerRef}
                    {...provided.droppableProps}
                    style={{minHeight: '100px'}}
                  >
                    <Flex
                      direction="column"
                      gap="x-small"
                      data-testid="widget-column-2"
                      width="100%"
                    >
                      {renderAddWidgetPlaceholder(2, 1)}
                      {widgetsByColumn[1].map((widget, index) => (
                        <React.Fragment key={widget.id}>
                          <Draggable draggableId={widget.id} index={index}>
                            {provided => (
                              <div
                                ref={provided.innerRef}
                                {...provided.draggableProps}
                                data-testid={`widget-container-${widget.id}`}
                              >
                                {renderWidget(widget, provided.dragHandleProps)}
                              </div>
                            )}
                          </Draggable>
                          {renderAddWidgetPlaceholder(2, widget.position.row + 1)}
                        </React.Fragment>
                      ))}
                      {provided.placeholder}
                    </Flex>
                  </div>
                )}
              </Droppable>
            ) : (
              <Flex direction="column" gap="x-small" data-testid="widget-column-2" width="100%">
                {widgetsByColumn[1].map(widget => (
                  <Flex.Item key={widget.id} data-testid={`widget-container-${widget.id}`}>
                    {renderWidget(widget)}
                  </Flex.Item>
                ))}
                {/* Ensure Flex renders even when empty */}
                {null}
              </Flex>
            )}
          </Flex.Item>
        </Flex>
      </DragDropContext>
    )
  }

  const renderColumnSection = (
    columnWidgets: Widget[],
    columnNumber: number,
    provided?: any,
    showTopPlaceholder = true,
  ) => {
    const content = isEditMode ? (
      <>
        {showTopPlaceholder && renderAddWidgetPlaceholder(columnNumber, 1)}
        {columnWidgets.map((widget, index) => (
          <React.Fragment key={widget.id}>
            <Draggable draggableId={widget.id} index={index}>
              {draggableProvided => (
                <div
                  ref={draggableProvided.innerRef}
                  {...draggableProvided.draggableProps}
                  data-testid={`widget-container-${widget.id}`}
                >
                  {renderWidget(widget, draggableProvided.dragHandleProps)}
                </div>
              )}
            </Draggable>
            {renderAddWidgetPlaceholder(columnNumber, widget.position.row + 1)}
          </React.Fragment>
        ))}
        {provided?.placeholder}
      </>
    ) : (
      columnWidgets.map(widget => renderWidgetInView(widget))
    )

    return (
      <Flex direction="column" gap="x-small" width="100%">
        {content}
      </Flex>
    )
  }

  const renderStackedLayout = () => {
    const stackedContent = (
      <Flex data-testid="widget-columns" direction="column" gap="small" width="100%">
        <Flex.Item
          data-testid="widget-column-1-stacked"
          overflowX="visible"
          overflowY="visible"
          width="100%"
        >
          {isEditMode ? (
            <Droppable droppableId="column-1">
              {provided => (
                <div
                  ref={provided.innerRef}
                  {...provided.droppableProps}
                  style={{minHeight: '50px'}}
                >
                  {renderColumnSection(widgetsByColumn[0], 1, provided)}
                </div>
              )}
            </Droppable>
          ) : (
            renderColumnSection(widgetsByColumn[0], 1)
          )}
        </Flex.Item>
        <Flex.Item
          data-testid="widget-column-2-stacked"
          overflowX="visible"
          overflowY="visible"
          width="100%"
        >
          {isEditMode ? (
            <Droppable droppableId="column-2">
              {provided => (
                <div
                  ref={provided.innerRef}
                  {...provided.droppableProps}
                  style={{minHeight: '50px'}}
                >
                  {renderColumnSection(widgetsByColumn[1], 2, provided, false)}
                </div>
              )}
            </Droppable>
          ) : (
            renderColumnSection(widgetsByColumn[1], 2, undefined, false)
          )}
        </Flex.Item>
      </Flex>
    )

    if (isEditMode) {
      return <DragDropContext onDragEnd={handleDragEnd}>{stackedContent}</DragDropContext>
    }

    return stackedContent
  }

  const renderTabletStack = renderStackedLayout
  const renderMobileStack = renderStackedLayout

  let gridContent
  if (matches.includes('mobile')) {
    gridContent = renderMobileStack()
  } else if (matches.includes('tablet')) {
    gridContent = renderTabletStack()
  } else {
    gridContent = renderDesktopGrid()
  }

  return (
    <>
      {gridContent}
      {addPosition && (
        <AddWidgetModal
          open={addModalOpen}
          onClose={() => {
            setAddModalOpen(false)
            setAddPosition(null)
          }}
          targetColumn={addPosition.col}
          targetRow={addPosition.row}
        />
      )}
    </>
  )
}

export default WidgetGrid
