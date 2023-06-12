// @ts-nocheck
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

import {DeepPartialOptional} from '../DeepPartialNullable'

/**
 * A type-safe way of ensuring we handle all properties of MockInstance. If any are added or removed in future versions
 * of jest, this code won't compile.
 */
const mockPropRecord: Record<'prototype' & keyof jest.MockInstance<any, any>, true> = {
  prototype: true,
  getMockName: true,
  mock: true,
  mockClear: true,
  mockReset: true,
  mockRestore: true,
  getMockImplementation: true,
  mockImplementation: true,
  mockImplementationOnce: true,
  mockName: true,
  mockReturnThis: true,
  mockReturnValue: true,
  mockReturnValueOnce: true,
  mockResolvedValue: true,
  mockResolvedValueOnce: true,
  mockRejectedValue: true,
  mockRejectedValueOnce: true,
}

/**
 * Creates a deep mock object, where all properties are jest mocks and are recursive.
 * Basically a recursive version of https://github.com/sebald/jest-mock-proxy
 *
 * Supports passing in a partial override record to specify specific literal values if needed.
 *
 * NOTE: For overriding object-type values in the root object, use `shallowOverrides`, as object type values in
 * `deepOverrides` are treated recursively.
 *
 * @param deepOverrides Record of non-object overrides; supports deep nesting
 * @param shallowOverrides Record of shallow overrides; supports object values
 * @param objectName Name of the object to use for mocks
 * @param nameInParent Name of the property in the parent object to use for mocks
 */
export function createDeepMockProxy<T>(
  deepOverrides: DeepPartialOptional<T> = {},
  shallowOverrides: Partial<T> = {},
  objectName = 'mock',
  nameInParent?: string | symbol
): DeepMocked<T> {
  const mock = jest.fn().mockName(objectName)
  const cache = new Map<any, any>()
  const setValues = new Map<string | symbol, any>()

  const extraImpl = {
    mockClear: () => {
      cache.clear()
      setValues.clear()
      mock.mockClear()
    },
  }

  const handler: ProxyHandler<typeof mock> = {
    apply(target: typeof mock, thisArg: any, argArray: any[]): any {
      // Handle calling the underlying mock
      return mock.apply(thisArg, argArray)
    },

    ownKeys(): ArrayLike<string | symbol> {
      return Array.from(
        new Set([
          ...Object.keys(extraImpl),
          ...Object.keys(mockPropRecord),
          ...Object.keys(shallowOverrides),
          ...Object.keys(deepOverrides),
        ])
      )
    },

    getOwnPropertyDescriptor(
      target: jest.Mock,
      name: string | symbol
    ): PropertyDescriptor | undefined {
      if (name in mockPropRecord) return Object.getOwnPropertyDescriptor(mock, name)
      if (name in extraImpl) return Object.getOwnPropertyDescriptor(extraImpl, name)
      if (name in shallowOverrides) return Object.getOwnPropertyDescriptor(shallowOverrides, name)
      if (name in deepOverrides) return Object.getOwnPropertyDescriptor(deepOverrides, name)
    },

    set(target: jest.Mock<any, any>, p: string | symbol, value: any): boolean {
      setValues.set(p, value)
      return true
    },

    get: (_, name) => {
      // Allow clearing the mock easily
      if (name in extraImpl) {
        return extraImpl[name]
      }

      // Special case because jest checks for spies by looking for a "calls" property with a "count" method.
      // we have to fail this check or jest will die since this isn't actually a spy
      if (nameInParent === 'calls' && name === 'count') {
        return undefined
      }

      if (setValues.has(name)) {
        return setValues.get(name)
      }

      // Allow calling methods on the underlying mock
      if (name in mock || mockPropRecord[name] === true) {
        return mock[name]
      }

      if (name in shallowOverrides) {
        return shallowOverrides[name]
      }

      if (name in deepOverrides) {
        const override = deepOverrides[name]

        // Generally we allow overriding with non-object values, because object values indicate recursion
        if (typeof override !== 'object') return override

        // But typeof null === 'object', and we want to allow null overriding
        if (override === null) return override

        // And typeof () => {} === 'object', and we want to allow function overrides
        if (override instanceof Function) return override
      }

      // Cache the properties we create so the same mock is returned on every property access
      if (!cache.has(name)) {
        cache.set(
          name,
          createDeepMockProxy(deepOverrides[name], {}, `${objectName}.${String(name)}`, name)
        )
      }

      return cache.get(name)
    },
  }

  return new Proxy(mock, handler) as unknown as DeepMocked<T>
}

export type DeepMocked<T> = {
  [P in keyof T]: T[P] extends (...args: any[]) => any
    ? jest.MockInstance<ReturnType<T[P]>, jest.ArgsType<T[P]>>
    : T[P] extends object | null | undefined
    ? DeepMocked<T[P]>
    : T[P]
} & T & {mockClear(): void}
