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
import {useEditor, useNode} from '@craftjs/core'
import {ButtonBlockToolbar} from './ButtonBlockToolbar'

import {getIcon} from '../../../../assets/icons'
import {Button, CondensedButton} from '@instructure/ui-buttons'
import {type ViewProps} from '@instructure/ui-view'
import {darken, lighten} from '@instructure/ui-color-utils'
import {getContrastingColor, white} from '../../../../utils'
import {isInstuiButtonColor} from './common'
import type {InstuiButtonColor, ButtonSize, ButtonVariant, ButtonBlockProps} from './common'

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
  } = useNode(state => ({
    customThemeOverride: state.data.custom.themeOverride || {},
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
      <CondensedButton
        elementRef={el => el && connect(drag(el as HTMLElement))}
        size={size}
        color={color}
        href={href?.trim() || '#'}
        renderIcon={iconName ? renderIcon : undefined}
        themeOverride={themeOverride}
        onClick={handleClick}
      >
        <span style={{whiteSpace: 'nowrap'}}>{text.trim()}</span>
      </CondensedButton>
    )
  } else {
    return (
      <Button
        themeOverride={themeOverride}
        elementRef={el => el && connect(drag(el as HTMLElement))}
        size={size}
        color={colorProp}
        withBackground={withBackground}
        href={href?.trim() || '#'}
        renderIcon={iconName ? renderIcon : undefined}
        onClick={handleClick}
      >
        <span style={{whiteSpace: 'nowrap'}}>{text.trim()}</span>
      </Button>
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
  },
  related: {
    toolbar: ButtonBlockToolbar,
  },
}

export {ButtonBlock, isInstuiButtonColor}
export type {ButtonBlockProps, ButtonSize, ButtonVariant, InstuiButtonColor}
