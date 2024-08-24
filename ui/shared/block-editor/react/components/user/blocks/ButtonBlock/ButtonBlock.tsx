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
import React, {useCallback} from 'react'
import {useEditor, useNode, type Node} from '@craftjs/core'
import {ButtonBlockToolbar} from './ButtonBlockToolbar'

import {getIcon} from '../../../../assets/user-icons'
import {Button, CondensedButton} from '@instructure/ui-buttons'
import {type ViewProps} from '@instructure/ui-view'
import {darken, lighten} from '@instructure/ui-color-utils'
import {getContrastingColor, white} from '../../../../utils/colorUtils'
import {isInstuiButtonColor} from './types'
import type {
  InstuiButtonColor,
  ButtonSize,
  ButtonVariant,
  ButtonBlockProps,
  InstuiCondensedButtonColor,
} from './types'

const ButtonBlock = ({
  text,
  size,
  variant,
  color,
  iconName,
  iconSize = 'x-small',
  href,
}: ButtonBlockProps) => {
  const {enabled} = useEditor(state => {
    return {
      enabled: state.options.enabled,
    }
  })
  const {
    connectors: {connect, drag},
    customThemeOverride,
    node,
  } = useNode((n: Node) => ({
    customThemeOverride: n.data.custom.themeOverride || {},
    node: n,
  }))

  const handleClick = useCallback(
    (event: React.KeyboardEvent<ViewProps> | React.MouseEvent<ViewProps>) => {
      if (enabled) {
        event.preventDefault()
      }
    },
    [enabled]
  )

  const renderIcon = useCallback(() => {
    const Icon = iconName ? getIcon(iconName) : null
    return Icon ? <Icon size={iconSize} /> : null
  }, [iconName, iconSize])

  const withBackground = variant !== 'outlined'

  // TODO: probably none of this if the theme is high contrast
  let colorProp: InstuiButtonColor | 'undefined' = 'primary'
  const themeOverride = {...customThemeOverride}
  if (isInstuiButtonColor(color)) {
    colorProp = color
  } else if (color) {
    if (!themeOverride.primaryColor) {
      themeOverride.primaryBackground = color
      const primaryColor = getContrastingColor(color)
      themeOverride.primaryColor = primaryColor
      if (themeOverride.primaryBackground) {
        const hoverColor =
          primaryColor === white
            ? lighten(themeOverride.primaryBackground, 10)
            : darken(themeOverride.primaryBackground, 10)
        themeOverride.primaryHoverBackground = hoverColor
      }
    }
  }

  if (variant === 'condensed') {
    return (
      <div
        role="treeitem"
        aria-label={node.data.displayName}
        aria-selected={node.events.selected}
        className="block button-block"
        ref={el => el && connect(drag(el as HTMLElement))}
        tabIndex={-1}
      >
        <CondensedButton
          data-testid="button-block"
          size={size}
          color={color as InstuiCondensedButtonColor}
          href={href?.trim() || '#'}
          renderIcon={iconName ? renderIcon : undefined}
          themeOverride={themeOverride}
          onClick={handleClick}
        >
          <span style={{whiteSpace: 'nowrap'}}>{text.trim()}</span>
        </CondensedButton>
      </div>
    )
  } else {
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
          themeOverride={themeOverride}
          size={size}
          color={colorProp}
          withBackground={withBackground}
          href={href?.trim() || '#'}
          renderIcon={iconName ? renderIcon : undefined}
          onClick={handleClick}
        >
          <span style={{whiteSpace: 'nowrap'}}>{text.trim()}</span>
        </Button>
      </div>
    )
  }
}

ButtonBlock.craft = {
  displayName: 'Button',
  defaultProps: {
    text: 'Button',
    href: '',
    size: 'medium',
    variant: 'filled',
    color: 'primary',
    iconName: '',
  },
  related: {
    toolbar: ButtonBlockToolbar,
  },
  custom: {
    isBlock: true,
  },
}

export {ButtonBlock, isInstuiButtonColor}
export type {ButtonBlockProps, ButtonSize, ButtonVariant, InstuiButtonColor}
