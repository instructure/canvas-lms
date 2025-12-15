/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

/**
 * Safe mock casting utility that works in both Jest and Vitest.
 *
 * This utility provides a type-safe way to access mock methods (mockReturnValue,
 * mockImplementation, etc.) on mocked functions without using unsafe type casts
 * like `(fn as jest.Mock)`.
 *
 * @example
 * // Instead of:
 * ;(myFunction as jest.Mock).mockReturnValue('value')
 *
 * // Use:
 * import {mocked} from '@canvas/test-utils/mocked'
 * mocked(myFunction).mockReturnValue('value')
 *
 * // Or use the global:
 * mocked(myFunction).mockReturnValue('value')
 *
 * @example
 * // Works with module mocks:
 * vi.mock('../myModule')
 * import {myFunction} from '../myModule'
 *
 * mocked(myFunction).mockReturnValue('test')
 * expect(mocked(myFunction)).toHaveBeenCalled()
 */

// Type definitions for mock functions that work with both Jest and Vitest
type MockInstance<T extends (...args: any[]) => any> = T & {
  mockClear: () => MockInstance<T>
  mockReset: () => MockInstance<T>
  mockRestore: () => void
  mockImplementation: (fn: T) => MockInstance<T>
  mockImplementationOnce: (fn: T) => MockInstance<T>
  mockReturnValue: (value: ReturnType<T>) => MockInstance<T>
  mockReturnValueOnce: (value: ReturnType<T>) => MockInstance<T>
  mockResolvedValue: (value: Awaited<ReturnType<T>>) => MockInstance<T>
  mockResolvedValueOnce: (value: Awaited<ReturnType<T>>) => MockInstance<T>
  mockRejectedValue: (value: unknown) => MockInstance<T>
  mockRejectedValueOnce: (value: unknown) => MockInstance<T>
  mockName: (name: string) => MockInstance<T>
  getMockName: () => string
  mock: {
    calls: Parameters<T>[]
    results: Array<{type: 'return' | 'throw'; value: unknown}>
    instances: unknown[]
    contexts: unknown[]
    lastCall: Parameters<T> | undefined
  }
}

// Deep mock type for mocking entire modules
type DeepMocked<T> = {
  [K in keyof T]: T[K] extends (...args: any[]) => any ? MockInstance<T[K]> : DeepMocked<T[K]>
}

/**
 * Type-safe utility to cast a function to its mocked version.
 *
 * This is equivalent to Jest's `jest.mocked()` and Vitest's `vi.mocked()`,
 * but works in both test runners and can be used as a global.
 *
 * @param fn - The function or module to cast to its mocked type
 * @returns The same function with mock method types available
 */
export function mocked<T extends (...args: any[]) => any>(fn: T): MockInstance<T>
export function mocked<T extends object>(obj: T): DeepMocked<T>
export function mocked<T>(item: T): T {
  return item as T
}

export default mocked
