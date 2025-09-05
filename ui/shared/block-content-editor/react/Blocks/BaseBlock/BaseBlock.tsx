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

import {ComponentProps} from 'react'
import {useIsInEditor} from '../../hooks/useIsInEditor'
import {useIsEditingBlock} from '../../hooks/useIsEditingBlock'
import {BaseBlockViewLayout} from './layout/BaseBlockViewLayout'
import {useBlockContentEditorContext} from '../../BlockContentEditorContext'
import {BaseBlockEditWrapper} from './components/BaseBlockEditWrapper'
import {Mask} from './components/Mask/Mask'
import {AccessibilityChecker} from './components/AccessibilityChecker'
import type {AccessibilityIssue} from '../../accessibilityChecker/types'

function BaseBlockViewerMode<T extends {}>(props: ComponentProps<typeof BaseBlock<T>>) {
  const Component = props.ViewComponent
  return (
    <BaseBlockViewLayout backgroundColor={props.backgroundColor}>
      <Component {...props.componentProps} />
    </BaseBlockViewLayout>
  )
}

function BaseBlockEditorMode<T extends {}>(props: ComponentProps<typeof BaseBlock<T>>) {
  const {settingsTray} = useBlockContentEditorContext()
  const {isEditingBlock} = useIsEditingBlock()

  const renderBlockContent = () => {
    const Component = isEditingBlock ? props.EditComponent : props.EditViewComponent

    if (isEditingBlock) {
      return <Component {...props.componentProps} />
    }

    return (
      <AccessibilityChecker componentProps={props.componentProps}>
        <Component {...props.componentProps} />
      </AccessibilityChecker>
    )
  }

  return (
    <BaseBlockEditWrapper title={props.title} backgroundColor={props.backgroundColor}>
      {renderBlockContent()}
      {settingsTray.isOpen && <Mask />}
    </BaseBlockEditWrapper>
  )
}

export function BaseBlock<T extends {}>(props: {
  ViewComponent: React.ComponentType<T>
  EditViewComponent: React.ComponentType<T>
  EditComponent: React.ComponentType<T>
  componentProps: T
  title: string
  backgroundColor?: string
  a11yCheck?: (props: T) => AccessibilityIssue[]
}) {
  const isInEditor = useIsInEditor()
  const Component = isInEditor ? BaseBlockEditorMode : BaseBlockViewerMode
  return <Component {...props} />
}
