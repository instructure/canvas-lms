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

// These are special webpack-processed imports that Typescript doesn't understand
// by default. Declaring them as wildcard modules allows TS to recognize them as
// bare-bones interfaces with the `any` type.
// See https://www.typescriptlang.org/docs/handbook/modules.html#wildcard-module-declarations
declare module '*.graphql'
declare module '*.handlebars'
declare module '*.svg' {
  const value: string
  export default value
}
declare module '*.module.css' {
  const classes: {readonly [key: string]: string}
  export default classes
}
declare module 'redux-logger' {
  import type {Middleware} from 'redux'
  export function createLogger(options?: {diff?: boolean; duration?: boolean}): Middleware
}

// Intl.DurationFormat is a newer ES API not yet in TypeScript's lib
declare namespace Intl {
  interface DurationFormatOptions {
    style?: 'long' | 'short' | 'narrow' | 'digital'
  }
  class DurationFormat {
    constructor(locales?: string | string[], options?: DurationFormatOptions)
    format(duration: {hours?: number; minutes?: number; seconds?: number}): string
  }
}

// @instructure/reactour has no type definitions
declare module '@instructure/reactour/dist/reactour.cjs' {
  import type {ComponentType} from 'react'
  interface ReactourProps {
    CustomHelper: ComponentType<any>
    steps: any[]
    isOpen: boolean
    onRequestClose: (options?: {forceClose?: boolean}) => void
  }
  const Reactour: ComponentType<ReactourProps & Record<string, any>>
  export default Reactour
}

// @instructure/ui-media-player has no type definitions
declare module '@instructure/ui-media-player' {
  import type {ComponentType} from 'react'
  interface MediaPlayerProps {
    sources: Array<{src?: string; label?: string; width?: string; height?: string}>
    tracks?: Array<{src?: string; label?: string; type?: string; language?: string}>
  }
  export const MediaPlayer: ComponentType<MediaPlayerProps & Record<string, any>>
}
