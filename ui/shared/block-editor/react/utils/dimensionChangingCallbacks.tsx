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

import React from 'react'
import {type MenuItemProps, type MenuItem} from '@instructure/ui-menu'
import type {
  ImageBlockProps,
  ImageConstraint,
} from '@canvas/block-editor/react/components/user/blocks/ImageBlock/types'
import {type ViewOwnProps} from '@instructure/ui-view'
import {changeSizeVariant} from '@canvas/block-editor/react/utils'
import type {SizeVariant} from '@canvas/block-editor/react/components/editor/types'

type SetPropFn = (updateFn: (props: ImageBlockProps) => void) => void

export function handleConstraintChange(setProp: SetPropFn) {
  return (
    _e: React.MouseEvent<ViewOwnProps, MouseEvent>,
    value: MenuItemProps['value'] | MenuItemProps['value'][],
    _selected: MenuItemProps['selected'],
    _args: MenuItem,
  ) => {
    const constraint = value as ImageConstraint | 'aspect-ratio'
    if (constraint === 'aspect-ratio') {
      setProp((prps: ImageBlockProps) => {
        prps.constraint = 'cover'
        prps.maintainAspectRatio = true
      })
    } else {
      setProp((prps: ImageBlockProps) => {
        prps.constraint = constraint
        prps.maintainAspectRatio = false
      })
    }
  }
}

export function handleChangeSzVariant(setProp: SetPropFn, node: {dom: HTMLElement | null}) {
  return (
    _e: React.MouseEvent<ViewOwnProps, MouseEvent>,
    value: MenuItemProps['value'] | MenuItemProps['value'][],
    _selected: MenuItemProps['selected'],
    _args: MenuItem,
  ) => {
    setProp((prps: ImageBlockProps) => {
      prps.sizeVariant = value as SizeVariant

      if (node.dom) {
        const {width, height} = changeSizeVariant(node.dom, value as SizeVariant)
        prps.width = width
        prps.height = height
      }
    })
  }
}
