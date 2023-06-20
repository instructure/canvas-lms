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

type HTMLElement = import('react').HTMLElement
type FC = import('react').FC
type KeyboardEventHandler = import('react').KeyboardEventHandler
type MouseEventHandler = import('react').MouseEventHandler
type ReactNode = import('react').ReactNode
type ChangeEvent = import('react').ChangeEvent

// These are special webpack-processed imports that Typescript doesn't understand
// by default. Declaring them as wildcard modules allows TS to recognize them as
// bare-bones interfaces with the `any` type.
// See https://www.typescriptlang.org/docs/handbook/modules.html#wildcard-module-declarations
declare module '*.graphql'
declare module '*.handlebars'
declare module '*.svg'

// InstUI v7 is missing type information for a lot of its props, so these suppress
// TS errors on valid props until we upgrade to v8.
interface MissingInputProps {
  onClick?: MouseEventHandler<HTMLElement>
  onKeyDown?: KeyboardEventHandler<HTMLElement>
  role?: string
  disabled?: boolean
}

interface MissingElementProps {
  onMouseEnter?: MouseEventHandler<HTMLElement>
  onMouseLeave?: MouseEventHandler<HTMLElement>
}

interface MissingThemeableProps {
  theme?: Record<string, unknown>
}

declare module '@instructure/ui-buttons' {
  export interface BaseButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface ButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface CloseButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface CondensedButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface IconButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface ToggleButtonProps extends MissingInputProps, MissingThemeableProps {}
  export const IconButton: FC<{
    theme: symbol
  }>
  export const Button: FC<{
    theme: symbol
  }>
  export const CloseButton: FC<{
    theme: symbol
  }>
  namespace BaseButton {
    export const theme: symbol
  }
  export const ButtonInteraction: FC<{
    theme: symbol
  }>
  export const CondensedButton: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-motion' {
  // export interface TransitionProps extends MissingThemeableProps {}
  export const Transition: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-form-field' {
  export interface FormMessage {
    text: ReactNode
    type: 'error' | 'hint' | 'success' | 'screenreader-only'
  }

  export const FormField: FC<{
    theme: symbol
  }>

  export const FormFieldGroup: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-text-input' {
  export interface TextInputProps extends MissingInputProps, MissingThemeableProps {
    defaultValue?: string
    messages?: import('@instructure/ui-form-field').FormMessage[]
    onChange?: (event: ChangeEvent<HTMLInputElement>, value: string) => void
  }

  export const TextInput: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-toggle-details' {
  export interface ToggleDetailsProps extends MissingThemeableProps {}
  export const ToggleDetails: FC<{
    theme: symbol
  }>
  export const ToggleGroup: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-view' {
  export interface ViewProps extends MissingElementProps, MissingThemeableProps {
    className?: string
  }
  export const View: FC<{
    theme: symbol
  }>
  export const ContextView: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-menu' {
  export const Menu: FC<{
    contentRef?: any
    theme: symbol
  }>
}

declare module '@instructure/ui-link' {
  export const Link: FC<{
    size?: string
    margin?: string
    isWithinText?: boolean
    as?: string
    theme: symbol
  }>
}

declare module '@instructure/ui-select' {
  export interface SelectProps {
    renderLabel?: string
  }
  export const Select: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-overlays' {
  export namespace Mask {
    export const theme: symbol
  }
}

declare module '@instructure/ui-heading' {
  export const Heading: FC<{
    level: string
  }>
}

declare module '@instructure/ui-checkbox' {
  export const ToggleFacade: FC<{
    theme: symbol
  }>
  export namespace CheckboxFacade {
    export const theme: symbol
  }
}

declare module '@instructure/ui-table' {
  export const Table: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-tag' {
  export const Tag: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-alerts' {
  export const Alert: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-tree-browser' {
  export namespace TreeBrowser {
    export const theme: symbol
    export namespace Node {
      export const theme: symbol
    }
    export namespace Button {
      export const theme: symbol
    }
  }
}

declare module '@instructure/ui-tabs' {
  export const Tabs: FC<{
    theme: symbol
  }>
}

declare module '@instructure/ui-badge' {
  export namespace Tabs {
    export const theme: symbol
    export namespace Tab {
      export const theme: symbol
    }
  }
}

declare module '@instructure/debounce' {
  type Function = (...args: any[]) => any

  interface Options {
    leading?: boolean
    maxWait?: number
    trailing?: boolean
  }

  export function debounce(func: Function, wait = 0, options?: Options): Function
}
