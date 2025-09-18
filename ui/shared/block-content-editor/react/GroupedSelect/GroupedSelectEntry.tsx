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

import './grouped-select.css'
import {Text} from '@instructure/ui-text'
import {forwardRef} from 'react'
import {View} from '@instructure/ui-view'

export const GroupedSelectEntry = forwardRef<
  HTMLDivElement,
  {
    variant: 'item' | 'group'
    title: string
    active: boolean
    onClick: () => void
    onFocus: () => void
  }
>((props, ref) => {
  const isItem = props.variant === 'item'
  const className = isItem ? 'grouped-select-item' : 'grouped-select-group'

  const handleElementRef = (element: Element | null) => {
    if (typeof ref === 'function') {
      ref(element as HTMLDivElement | null)
    } else if (ref && 'current' in ref) {
      ref.current = element as HTMLDivElement | null
    }
  }

  return (
    <View
      as="button"
      type="button"
      background="transparent"
      borderColor="transparent"
      borderWidth="none"
      textAlign="start"
      width="100%"
      elementRef={handleElementRef}
      aria-selected={props.active}
      className={`${className} ${props.active ? 'selected' : ''}`}
      onClick={props.onClick}
      onFocus={props.onFocus}
    >
      <Text variant="content">{props.title}</Text>
    </View>
  )
})
