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
import React, {useCallback, useRef} from 'react'
import {useEditor, useNode, type Node} from '@craftjs/core'
import {ButtonBlockToolbar} from './ButtonBlockToolbar'

import {getIcon} from '../../../../assets/user-icons'
import {Button} from '@instructure/ui-buttons'
import {type ViewProps} from '@instructure/ui-view'
import {darken, lighten} from '@instructure/ui-color-utils'
import {
  getContrastingColor,
  getEffectiveBackgroundColor,
  white,
  black,
} from '../../../../utils/colorUtils'
import type {ButtonSize, ButtonVariant, ButtonBlockProps} from './types'

const ButtonBlock = ({
  text,
  size,
  variant,
  color,
  background,
  borderColor,
  iconName,
  href,
}: ButtonBlockProps) => {
  const {enabled} = useEditor(state => {
    return {
      enabled: state.options.enabled,
    }
  })
  const {
    connectors: {connect, drag},
    node,
  } = useNode((n: Node) => ({
    node: n,
  }))
  const buttonRef = useRef<HTMLButtonElement | null>(null)

  const handleClick = useCallback(
    (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      if (enabled) {
        event.preventDefault()
      }
    },
    [enabled],
  )

  const getThemeOverride = () => {
    let themeOverride = {}
    let bg, clr, hovercolor
    switch (variant) {
      case 'text':
        bg = getEffectiveBackgroundColor(buttonRef.current)
        clr = getContrastingColor(bg)
        hovercolor = clr === white ? lighten(bg, 10) : darken(bg, 10)

        themeOverride = {
          secondaryColor: color || clr,
          secondaryBackground: 'transparent',
          secondaryBorderColor: 'transparent',
          secondaryHoverBackground: hovercolor,
        }
        break
      case 'outlined':
        bg = getEffectiveBackgroundColor(buttonRef.current)
        clr = getContrastingColor(bg)
        hovercolor = clr === white ? lighten(bg, 10) : darken(bg, 10)

        themeOverride = {
          secondaryColor: color || clr,
          secondaryBackground: 'transparent',
          secondaryBorderColor: borderColor || clr,
          secondaryHoverBackground: hovercolor,
        }
        break
      case 'filled':
        bg = background || black
        clr = getContrastingColor(bg)
        hovercolor = clr === white ? lighten(bg, 10) : darken(bg, 10)

        themeOverride = {
          secondaryColor: color || clr,
          secondaryBackground: background || black,
          secondaryBorderColor: borderColor || black,
          secondaryHoverBackground: background ? hovercolor : lighten(black, 10),
        }
        break
    }
    return themeOverride
  }

  const renderIcon = useCallback(() => {
    const Icon = iconName ? getIcon(iconName) : null
    return Icon ? <Icon size="x-small" /> : null
  }, [iconName])

  return (
    <div
      role="treeitem"
      aria-label={node.data.displayName}
      aria-selected={node.events.selected}
      className="block button-block"
      ref={el => el && connect(drag(el as HTMLElement))}
      tabIndex={-1}
    >
      <Button
        data-testid="button-block"
        elementRef={el => (buttonRef.current = el as HTMLButtonElement)}
        color="secondary"
        href={href}
        renderIcon={iconName ? renderIcon : undefined}
        size={size}
        themeOverride={getThemeOverride()}
        onClick={handleClick}
      >
        {text.trim()}
      </Button>
    </div>
  )
}

ButtonBlock.craft = {
  displayName: 'Button',
  defaultProps: {
    text: 'Button',
    href: '',
    size: 'medium',
    variant: 'filled',
    iconName: '',
  },
  related: {
    toolbar: ButtonBlockToolbar,
  },
  custom: {
    isBlock: true,
  },
}

export {ButtonBlock}
export type {ButtonBlockProps, ButtonSize, ButtonVariant}
