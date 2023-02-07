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

import {HTMLElement, KeyboardEventHandler, MouseEventHandler} from 'react'

// These are special webpack-processed imports that Typescript doesn't understand
// by default. Declaring them as wildcard modules allows TS to recognize them as
// bare-bones interfaces with the `any` type.
// See https://www.typescriptlang.org/docs/handbook/modules.html#wildcard-module-declarations
declare module '*.coffee'
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
  theme?: object
}

declare module '@instructure/ui-buttons' {
  export interface BaseButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface ButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface CloseButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface CondensedButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface IconButtonProps extends MissingInputProps, MissingThemeableProps {}
  export interface ToggleButtonProps extends MissingInputProps, MissingThemeableProps {}
  namespace IconButton {
    export const theme: symbol
  }
  namespace Button {
    export const theme: symbol
  }
  namespace CloseButton {
    export const theme: symbol
  }
  namespace BaseButton {
    export const theme: symbol
  }
}

declare module '@instructure/ui-motion' {
  export interface TransitionProps extends MissingThemeableProps {}
}

declare module '@instructure/ui-text-input' {
  export interface TextInputProps extends MissingInputProps {}
  export namespace TextInput {
    export const theme: symbol
  }
}

declare module '@instructure/ui-toggle-details' {
  export interface ToggleDetailsProps extends MissingThemeableProps {}
  export namespace ToggleDetails {
    export const theme: symbol
  }
}

declare module '@instructure/ui-view' {
  export interface ViewProps extends MissingElementProps, MissingThemeableProps {
    className?: string
  }
  export namespace View {
    export const theme: symbol
  }
}

declare module '@instructure/ui-buttons' {
  export interface ButtonProps {
    id?: string
  }
}

declare module '@instructure/ui-menu' {
  export interface Menu {
    contentRef?: any
  }
  export namespace Menu {
    export const theme: symbol
  }
}

declare module '@instructure/ui-link' {
  export interface Link {
    size?: string
    margin?: string
    isWithinText?: boolean
    as?: string
  }
  export namespace Link {
    export const theme: symbol
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

declare module '@instructure/ui-overlays' {
  export namespace Mask {
    export const theme: symbol
  }
}

declare module '@instructure/ui-heading' {
  export namespace Heading {
    export const theme: symbol
  }
}

declare module '@instructure/ui-checkbox' {
  export namespace ToggleFacade {
    export const theme: symbol
  }
  export namespace CheckboxFacade {
    export const theme: symbol
  }
}

declare module '@instructure/ui-table' {
  export namespace Table {
    export const theme: symbol
    export namespace Cell {
      export const theme: symbol
    }
    export namespace Row {
      export const theme: symbol
    }
    export namespace ColHeader {
      export const theme: symbol
    }
  }
}

declare module '@instructure/ui-tag' {
  export namespace Tag {
    export const theme: symbol
  }
}

declare module '@instructure/ui-alerts' {
  export namespace Alert {
    export const theme: symbol
  }
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
  export namespace Tabs {
    export const theme: symbol
    export namespace Tab {
      export const theme: symbol
    }
  }
}

declare module '@instructure/ui-badge' {
  export namespace Tabs {
    export const theme: symbol
    export namespace Tab {
      export const theme: symbol
    }
  }
}
