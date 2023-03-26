/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import * as JQuery from 'jquery'

// for some reason, there's an extra `keyString` property on this event
type KeyDownEvent = JQuery.KeyDownEvent & {keyString: string}

type KeycodesCallback = (this: HTMLElement, event: KeyDownEvent) => void

declare global {
  declare interface JQuery {
    keycodes: {
      (options: string, fn: KeycodesCallback): JQuery<HTMLElement>
      (options: {ignore: string; keyCodes: string}, fn: KeycodesCallback): JQuery<HTMLElement>
    }
  }
}

// Global scope declarations are only allowed in module contexts, so we
// need this to make Typescript think this is a module.
export {}
