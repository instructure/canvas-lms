/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
 * Extract from `T` those types that are assignable to `U`, but only allows values present in `T`
 *
 * This is a more type safe version of the built-in `Extract`.
 *
 *
 * @example
 * // Imagine a type encoding the valid CSS border-style values:
 *
 * type CssBorderStyle = 'dotted'
 *                     | 'dashed'
 *                     | 'solid'
 *                     | 'double'
 *                     | 'groove'
 *                     | 'ridge'
 *                     | 'inset'
 *                     | 'outset'
 *                     | 'none'
 *                     | 'hidden'
 *
 *
 * // We might want to have a function that only supports a subset of that list, but we want the compiler to ensure
 * // we didn't make a mistake. The following would compile:
 *
 *
 * function applyValidBorder(
 *   style: ExtractRequired<CssBorderStyle, 'solid' | 'none' | 'dashed'>
 * ){  }
 *
 *
 * // But this would not compile, since 'unsolid' isn't in `CssBorderStyle`:
 *
 *
 * function applyValidBorder(
 *   style: ExtractRequired<CssBorderStyle, 'unsolid' | 'none' | 'dashed'>
 * ) {  }
 *
 *
 * // This is helpful if a value is later removed from `CssBorderStyle`: All uses of that value will become compiler
 * // errors.
 */
export type ExtractRequired<TSuperset, TSubset extends TSuperset> = TSuperset extends TSubset
  ? TSuperset
  : never
