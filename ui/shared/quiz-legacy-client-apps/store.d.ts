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

export interface StorePrototype<T = any> {
  actions?: Record<string, (...args: any[]) => any>
  getInitialState(): T
  setState(newState: Partial<T>): void
  [key: string]: any
}

export interface StoreInstance<T = any> {
  _key: string
  state: T
  _callbacks: Array<() => void>
  actions: Record<string, (...args: any[]) => any>
  addChangeListener(callback: () => void): void
  removeChangeListener(callback: () => void): void
  emitChange(): void
  __reset__(): void
  getInitialState(): T
  setState(newState: Partial<T>): void
}

declare class Store<T = any> implements StoreInstance<T> {
  constructor(key: string, proto?: StorePrototype<T>, Dispatcher?: any)

  _key: string
  state: T
  _callbacks: Array<() => void>
  actions: Record<string, (...args: any[]) => any>

  addChangeListener(callback: () => void): void
  removeChangeListener(callback: () => void): void
  emitChange(): void
  __reset__(): void
  getInitialState(): T
  setState(newState: Partial<T>): void

  [key: string]: any
}

export default Store
