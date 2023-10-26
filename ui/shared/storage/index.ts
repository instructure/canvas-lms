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

interface CustomStorage extends Storage {
  data: {[key: string]: string}
}

export const memoryStorage: CustomStorage = {
  data: {},
  getItem(key: string): string | null {
    return key in this.data ? this.data[key] : null
  },
  setItem(key: string, value: string) {
    this.data[key] = value
  },
  removeItem(key: string) {
    delete this.data[key]
  },
  clear() {
    this.data = {}
  },
  get length() {
    return Object.keys(this.data).length
  },
  key(index: number): string | null {
    const keys = Object.keys(this.data)
    return keys[index] || null
  },
}

let localOrMemoryStorage: Storage

try {
  // Some browsers don't allow you to access sessionStorage in some contexts
  localOrMemoryStorage = window.localStorage
} catch (e) {
  // eslint-disable-next-line no-console
  console.warn('Falling back to memory storage', e)
  localOrMemoryStorage = memoryStorage
}

const localStorage = localOrMemoryStorage

let sessionOrMemoryStorage: Storage

try {
  // Some browsers don't allow you to access sessionStorage in some contexts
  sessionOrMemoryStorage = window.sessionStorage
} catch (e) {
  // eslint-disable-next-line no-console
  console.warn('Falling back to memory storage', e)
  sessionOrMemoryStorage = memoryStorage
}

const sessionStorage = sessionOrMemoryStorage

export {localStorage, sessionStorage}
