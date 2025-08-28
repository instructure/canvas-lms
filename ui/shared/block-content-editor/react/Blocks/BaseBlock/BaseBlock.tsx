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

import {ComponentProps, ElementType, PropsWithChildren, useState} from 'react'
import {BlockContext} from './BaseBlockContext'
import {useGetRenderMode} from './useGetRenderMode'
import {BaseBlockViewLayout} from './layout/BaseBlockViewLayout'
import {BaseBlockEditWrapper} from './components/BaseBlockEditWrapper'
import {useGenHistoryKey} from '../../hooks/useGenHistoryKey'
import {useIsInEditor} from '../../hooks/useIsInEditor'
import {BaseBlockView} from './BaseBlockView'
import {BaseBlockEdit} from './BaseBlockEdit'
import {useIsEditingBlock} from '../../hooks/useIsEditingBlock'

const BaseBlockContent = (
  props: ComponentProps<typeof BaseBlock> & {
    setIsEditMode: (isEditMode: boolean) => void
  },
) => {
  const {isViewMode, isEditMode} = useGetRenderMode()
  return isViewMode ? (
    <BaseBlockViewLayout backgroundColor={props.backgroundColor}>
      {props.children}
    </BaseBlockViewLayout>
  ) : (
    <BaseBlockEditWrapper {...props} isEditMode={isEditMode} />
  )
}

type BaseBlockProps<T extends ElementType> = PropsWithChildren<{
  title: string
  backgroundColor?: string
  statefulProps: Partial<ComponentProps<T>>
}>

export function BaseBlock<T extends ElementType>(props: BaseBlockProps<T>) {
  const [isEditMode, setIsEditMode] = useState(false)
  const historyKey = useGenHistoryKey(props.statefulProps)
  return (
    <BlockContext.Provider value={{isEditMode}}>
      <BaseBlockContent key={historyKey} {...props} setIsEditMode={setIsEditMode} />
    </BlockContext.Provider>
  )
}

function BaseBlockViewerMode<T extends {}>(props: ComponentProps<typeof BaseBlockHOC<T>>) {
  const Component = props.ViewComponent
  return (
    <BaseBlockView backgroundColor={props.backgroundColor ?? ''}>
      <Component {...props.componentProps} />
    </BaseBlockView>
  )
}

function BaseBlockEditorMode<T extends {}>(props: ComponentProps<typeof BaseBlockHOC<T>>) {
  const isEditing = useIsEditingBlock()
  const Component = isEditing ? props.EditComponent : props.EditViewComponent
  return (
    <BaseBlockEdit title={props.title} backgroundColor={props.backgroundColor ?? ''}>
      <Component {...props.componentProps} />
    </BaseBlockEdit>
  )
}

export function BaseBlockHOC<T extends {}>(props: {
  ViewComponent: React.ComponentType<T>
  EditViewComponent: React.ComponentType<T>
  EditComponent: React.ComponentType<T>
  componentProps: T
  title: string
  backgroundColor?: string
}) {
  const isInEditor = useIsInEditor()
  const Component = isInEditor ? BaseBlockEditorMode : BaseBlockViewerMode
  return <Component {...props} />
}
