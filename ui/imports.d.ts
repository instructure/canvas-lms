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

declare module 'convert-case' {
  export function camelize<T>(props: {[key: string]: unknown}): T
  export function underscore<T>(props: {[key: string]: unknown}): T
}

// Global scope declarations are only allowed in module contexts, so we
// need this to make Typescript think this is a module. 🙄
export {}
