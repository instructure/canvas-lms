/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Component, FocusEventHandler, KeyboardEventHandler, MouseEventHandler} from 'react'
import * as PropTypes from 'prop-types'
import {InferType, Requireable} from 'prop-types'
import {ThemeablePropTypes} from '@instructure/ui-themeable'

interface MissingElementProps {
  onMouseEnter?: MouseEventHandler<HTMLElement>
  onMouseLeave?: MouseEventHandler<HTMLElement>
  onClick?: MouseEventHandler<HTMLElement>
  onKeyDown?: KeyboardEventHandler<HTMLElement>
  onFocus?: FocusEventHandler<HTMLElement>
  onBlur?: FocusEventHandler<HTMLElement>
  role?: string
  tabIndex?: string | number
}

// InstUI v7 is missing type information for a lot of its props, so these suppress
// TS errors on valid props until we upgrade to v8.
interface MissingInputProps extends MissingElementProps {
  disabled?: boolean
}

interface MissingThemeableProps {
  theme?: object
}

declare module '@instructure/ui-buttons' {
  export interface BaseButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface ButtonProps extends MissingInputProps, MissingThemeableProps {
    id?: string
  }
  export interface CloseButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface CondensedButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface IconButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface ToggleButtonProps extends MissingInputProps, MissingThemeableProps {}
}

declare module '@instructure/ui-motion' {
  export interface TransitionProps extends MissingThemeableProps {}
}

declare module '@instructure/ui-text-input' {
  export interface TextInputProps extends MissingInputProps {}
}

declare module '@instructure/ui-toggle-details' {
  export interface ToggleDetailsProps extends MissingThemeableProps {}
}

declare module '@instructure/ui-view' {
  export interface ViewProps extends MissingElementProps, MissingThemeableProps {
    className?: string
    type?: string
  }
}

declare module '@instructure/ui-menu' {
  export interface Menu {
    contentRef?: any
  }
}

declare module '@instructure/ui-link' {
  export interface Link {
    size?: string
    margin?: string
    isWithinText?: boolean
    as?: string
  }
}

declare module '@instructure/ui-text' {
  export interface Text {
    tag?: string
  }
}

declare module '@instructure/ui-select' {
  export interface SelectProps {
    renderLabel?: string
  }
}
declare module '@instructure/ui-themeable' {
  type ShorthandPropType<T extends string> =
    | `${T}`
    | `${T} ${T}`
    | `${T} ${T} ${T}`
    | `${T} ${T} ${T} ${T}`

  declare namespace ThemeablePropTypes {
    type ShadowValue = 'resting' | 'above' | 'topmost' | 'none'

    type StackingValue = 'deepest' | 'below' | 'resting' | 'above' | 'topmost'

    type BorderWidthValue = '0' | 'none' | 'small' | 'medium' | 'large'

    type BorderRadiusValue = '0' | 'none' | 'small' | 'medium' | 'large' | 'circle' | 'pill'

    type BackgroundValue = 'default' | 'inverse' | 'transparent'

    type SizeValue = 'x-small' | 'small' | 'medium' | 'large' | 'x-large'

    type SpacingValue =
      | '0'
      | 'none'
      | 'auto'
      | 'xxx-small'
      | 'xx-small'
      | 'x-small'
      | 'small'
      | 'medium'
      | 'large'
      | 'x-large'
      | 'xx-large'
  }

  export const ThemeablePropTypes: {
    shadow: PropTypes.Requireable<ThemeablePropTypes.ShadowValue>
    stacking: PropTypes.Requireable<ThemeablePropTypes.StackingValue>
    borderWidth: PropTypes.Requireable<ShorthandPropType<ThemeablePropTypes.BorderWidthValue>>
    borderRadius: PropTypes.Requireable<ShorthandPropType<ThemeablePropTypes.BorderRadiusValue>>
    background: PropTypes.Requireable<ThemeablePropTypes.BackgroundValue>
    size: PropTypes.Requireable<ThemeablePropTypes.SizeValue>
    spacing: PropTypes.Requireable<ShorthandPropType<ThemeablePropTypes.SpacingValue>>
  }
}

declare module '@instructure/ui-list' {
  declare namespace List {
    export type ItemProps = PropTypes.InferProps<{
      children: Requireable<NonNullable<InferType<typeof PropTypes.node | typeof PropTypes.func>>>
      /**
       * Inherits delimiter from the parent List component.
       */
      delimiter: Requireable<'none' | 'dashed' | 'solid' | 'pipe' | 'slash' | 'arrow'>

      size: Requireable<'small' | 'medium' | 'large'>
      /**
       * Valid values are `0`, `none`, `auto`, `xxx-small`, `xx-small`, `x-small`,
       * `small`, `medium`, `large`, `x-large`, `xx-large`. Apply these values via
       * familiar CSS-like shorthand. For example: `margin="small auto large"`.
       */
      margin: ThemeablePropTypes.spacing
      /**
       * Valid values are `0`, `none`, `xxx-small`, `xx-small`, `x-small`,
       * `small`, `medium`, `large`, `x-large`, `xx-large`. Apply these values via
       * familiar CSS-like shorthand. For example: `padding="small x-large large"`.
       */
      padding: ThemeablePropTypes.spacing
      /**
       * Inherits itemSpacing from the parent List component
       */
      spacing: Requireable<
        | 'none'
        | 'xxx-small'
        | 'xx-small'
        | 'x-small'
        | 'small'
        | 'medium'
        | 'large'
        | 'x-large'
        | 'xx-large'
      >
      elementRef: PropTypes.func
      /**
       * __deprecated:__ inline will be InlineList
       */
      variant: Requireable<'default' | 'unstyled' | 'inline'>
    }>

    // eslint-disable-next-line react/prefer-stateless-function
    export class Item extends Component<ItemProps, any> {}
  }
}

declare module '@instructure/ui-flex' {
  declare namespace Flex {
    export type ItemProps = PropTypes.InferProps<{
      /**
       * The children to render inside the Item`
       */
      children: PropTypes.node
      /**
       * the element type to render as
       */
      as: PropTypes.elementType
      /**
       * provides a reference to the underlying html root element
       */
      elementRef: PropTypes.func
      /**
       * Valid values are `0`, `none`, `auto`, `xxx-small`, `xx-small`, `x-small`,
       * `small`, `medium`, `large`, `x-large`, `xx-large`. Apply these values via
       * familiar CSS-like shorthand. For example: `margin="small auto large"`.
       */
      margin: ThemeablePropTypes.spacing
      /**
       * Valid values are `0`, `none`, `xxx-small`, `xx-small`, `x-small`,
       * `small`, `medium`, `large`, `x-large`, `xx-large`. Apply these values via
       * familiar CSS-like shorthand. For example: `padding="small x-large large"`.
       */
      padding: ThemeablePropTypes.spacing
      /**
       * overrides the parent Flex's alignItems prop, if needed
       */
      align: PropTypes.Requireable<'center' | 'start' | 'end' | 'stretch'>
      /**
       * Inherits from the parent Flex component
       */
      direction: PropTypes.Requireable<'row' | 'column'>
      /**
       * Designates the text alignment inside the Item
       */
      textAlign: PropTypes.Requireable<'start' | 'center' | 'end'>
      /**
       * Handles horizontal overflow
       */
      overflowX: PropTypes.Requireable<'auto' | 'hidden' | 'visible'>
      /**
       * Handles vertical overflow
       */
      overflowY: PropTypes.Requireable<'auto' | 'hidden' | 'visible'>
      /**
       * Should the FlexItem grow to fill any available space?
       */
      shouldGrow: PropTypes.bool
      /**
       * Should the FlexItem shrink (stopping at its `size`)?
       */
      shouldShrink: PropTypes.bool
      /**
       * Sets the base size of the FlexItem (width if direction is `row`; height if direction is `column`)
       */
      size: PropTypes.string
      /**
       * Places dashed lines around the component's borders to help debug your layout
       */
      withVisualDebug: PropTypes.bool

      /**
       * __Deprecated - use 'shouldGrow'__
       */
      grow: PropTypes.bool
      /**
       * __Deprecated - use 'shouldShrink'__
       */
      shrink: PropTypes.bool
      /**
       * __Deprecated - use 'withVisualDebug'__
       */
      visualDebug: PropTypes.bool
    }>

    // eslint-disable-next-line react/prefer-stateless-function
    export class Item extends Component<ItemProps, any> {}
  }
}

declare module '@instructure/ui-modal' {
  declare namespace Modal {
    export type BodyProps = PropTypes.InferProps<{
      children: PropTypes.node
      padding: ThemeablePropTypes.spacing
      elementRef: PropTypes.func
      as: PropTypes.elementType
      variant: Requireable<'default' | 'inverse'>
      overflow: Requireable<'scroll' | 'fit'>
    }>
    // eslint-disable-next-line react/prefer-stateless-function
    export class Body extends Component<BodyProps, any> {}

    export type FooterProps = PropTypes.InferProps<{
      children: PropTypes.node
      variant: Requireable<'default' | 'inverse'>
    }>
    // eslint-disable-next-line react/prefer-stateless-function
    export class Footer extends Component<FooterProps, any> {}

    export type HeaderProps = PropTypes.InferProps<{
      children: PropTypes.node
      variant: Requireable<'default' | 'inverse'>
      spacing: Requireable<'default' | 'compact'>
    }>
    // eslint-disable-next-line react/prefer-stateless-function
    export class Header extends Component<HeaderProps, any> {}
  }
}
