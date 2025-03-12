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

import React from 'react'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import ModuleItem from './ModuleItem'
import {Droppable, Draggable} from 'react-beautiful-dnd'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {CompletionRequirement} from '../utils/types'
import {ModuleItem as ModuleItemType} from '../utils/types'

const I18n = createI18nScope('context_modules_v2')

export interface ModuleItemListProps {
  moduleId: string
  moduleItems: ModuleItemType[]
  completionRequirements?: CompletionRequirement[]
  isLoading: boolean
  error: any
}

const ModuleItemList: React.FC<ModuleItemListProps> = ({
  moduleId,
  moduleItems,
  completionRequirements,
  isLoading,
  error,
}) => {
  return (
    <View
      as="div"
      overflowX="hidden"
    >
      <Droppable droppableId={moduleId} type="MODULE_ITEM">
        {(provided, snapshot) => (
          <div
            ref={provided.innerRef}
            {...provided.droppableProps}
            style={{
              minHeight: '50px',
              background: snapshot.isDraggingOver ? '#f5f5f5' : 'transparent',
              padding: '4px 0',
              overflowX: 'hidden'
            }}
          >
            {isLoading ? (
              <View as="div" textAlign="center" padding="medium">
                <Spinner renderTitle={I18n.t('Loading module items')} size="small" />
              </View>
            ) : error ? (
              <View as="div" textAlign="center" padding="medium">
                <Text color="danger">{I18n.t('Error loading module items')}</Text>
              </View>
            ) : moduleItems.length === 0 ? (
              <View as="div" textAlign="center" padding="medium">
                <Text>{I18n.t('No items in this module')}</Text>
              </View>
            ) : (
              moduleItems.map((item, index) => (
                <Draggable key={`${item.id}-${index}`} draggableId={item.id} index={index}>
                  {(dragProvided, dragSnapshot) => (
                    <div
                      ref={dragProvided.innerRef}
                      {...dragProvided.draggableProps}
                      style={{
                        ...dragProvided.draggableProps.style,
                        background: dragSnapshot.isDragging ? '#ffffff' : 'transparent',
                        boxShadow: dragSnapshot.isDragging ? '0 2px 8px rgba(0,0,0,0.15)' : 'none',
                        borderRadius: '4px',
                        margin: '2px 0',
                        overflowX: 'hidden'
                      }}
                      data-item-id={item._id}
                    >
                      <View as="div" borderWidth={`${index === 0 ? '0' : 'small'} 0 0 0`} borderRadius="small">
                        <ModuleItem
                          {...item}
                          moduleId={moduleId}
                          index={index}
                          id={item.id}
                          published={item.content?.published || false}
                          canUnpublish={item.content?.canUnpublish || false}
                          completionRequirements={completionRequirements}
                          dragHandleProps={dragProvided.dragHandleProps}
                        />
                      </View>
                    </div>
                  )}
                </Draggable>
              ))
            )}
            {provided.placeholder}
          </div>
        )}
      </Droppable>
    </View>
  )
}

export default ModuleItemList
