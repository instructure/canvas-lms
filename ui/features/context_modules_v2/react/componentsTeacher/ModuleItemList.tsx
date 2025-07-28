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

import React, {memo} from 'react'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import ModuleItem from './ModuleItem'
import AddItemInline from './AddItemModalComponents/AddItemInline'
import {Droppable, Draggable} from 'react-beautiful-dnd'
import {useScope as createI18nScope} from '@canvas/i18n'
import type {
  CompletionRequirement,
  ModuleItem as ModuleItemType,
  ModuleAction,
} from '../utils/types'
import {validateModuleItemTeacherRenderRequirements} from '../utils/utils'

const I18n = createI18nScope('context_modules_v2')

const MemoizedModuleItem = memo(ModuleItem, validateModuleItemTeacherRenderRequirements)

export interface ModuleItemListProps {
  moduleId: string
  moduleTitle?: string
  moduleItems: ModuleItemType[]
  completionRequirements?: CompletionRequirement[]
  isLoading: boolean
  error: any
  setModuleAction?: React.Dispatch<React.SetStateAction<ModuleAction | null>>
  setSelectedModuleItem?: (item: {id: string; title: string} | null) => void
  setIsManageModuleContentTrayOpen?: React.Dispatch<React.SetStateAction<boolean>>
  setSourceModule?: React.Dispatch<React.SetStateAction<{id: string; title: string} | null>>
}

const ModuleItemList: React.FC<ModuleItemListProps> = ({
  moduleId,
  moduleTitle = '',
  moduleItems,
  completionRequirements,
  isLoading,
  error,
  setModuleAction,
  setSelectedModuleItem,
  setIsManageModuleContentTrayOpen,
  setSourceModule,
}) => {
  return (
    <View as="div" overflowX="hidden">
      <Droppable droppableId={moduleId} type="MODULE_ITEM">
        {(provided, snapshot) => (
          <div
            ref={provided.innerRef}
            {...provided.droppableProps}
            style={{
              minHeight: '50px',
              background: snapshot.isDraggingOver ? '#F2F4F4' : 'transparent',
              padding: '0',
              overflowX: 'hidden',
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
                <AddItemInline moduleId={moduleId} itemCount={0} />
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
                        overflowX: 'hidden',
                        borderWidth: item.content?.published ? '0 0 0 large' : '0',
                        borderColor: 'success',
                      }}
                      data-item-id={item._id}
                    >
                      <View as="div" borderWidth={`${index === 0 ? '0' : 'small'} 0 0 0`}>
                        <View
                          as="div"
                          borderWidth="0 0 0 large"
                          borderColor={item.content?.published ? 'success' : 'transparent'}
                        >
                          <MemoizedModuleItem
                            {...item}
                            moduleId={moduleId}
                            moduleTitle={moduleTitle}
                            index={index}
                            id={item.id}
                            published={item.content?.published ?? false}
                            canUnpublish={item.content?.canUnpublish ?? true}
                            completionRequirements={completionRequirements}
                            dragHandleProps={dragProvided.dragHandleProps}
                            setModuleAction={setModuleAction}
                            setSelectedModuleItem={setSelectedModuleItem}
                            setIsManageModuleContentTrayOpen={setIsManageModuleContentTrayOpen}
                            setSourceModule={setSourceModule}
                          />
                        </View>
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
