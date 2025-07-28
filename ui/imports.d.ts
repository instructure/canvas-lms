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
