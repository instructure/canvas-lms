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

/**
 * Helper type that takes an input Record type and produces a copy where all properties are optional and nullable,
 * recursively.
 *
 * Useful for declaring the type of unsafe input JSON to ensure that proper null checking is handled.
 */
export type DeepPartialNullable<T> = {
  [K in keyof T]?: (T[K] extends object ? DeepPartialNullable<T[K]> : T[K]) | null
}

/**
 * Implementation of DeepPartial that handles children that may be optional or nullable.
 */
export type DeepPartialOptional<T> = {
  [K in keyof T]?: T[K] extends object
    ? DeepPartialOptional<T[K]>
    : T[K] extends object | null
    ? DeepPartialOptional<T[K]> | null
    : T[K] extends object | undefined
    ? DeepPartialOptional<T[K]> | undefined
    : T[K] extends object | null | undefined
    ? DeepPartialOptional<T[K]> | null | undefined
    : T[K]
}
