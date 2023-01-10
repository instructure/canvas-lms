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
 * Used to ensure in a type safe way that some variable cannot ever be in a particular state.
 * Useful for exhaustive switch statements, where the compiler will ensure all possible cases are covered.
 *
 * For example:
 *
 * ```
 * const someValue: 'a' | 'b' = ...
 *
 * switch (someValue) {
 *   case 'a': return whatever();
 *   case 'b': return whatever();
 *
 *   // If all possible values of someValue aren't handled above, this will fail to compile
 *   default: assertNever(someValue);
 * }
 *
 * ```
 *
 * Inspired by https://stackoverflow.com/questions/39419170/how-do-i-check-that-a-switch-block-is-exhaustive-in-typescript
 *
 * @param input
 */
export function assertNever(input: never): never {
  throw new Error(
    'Should not be reachable, something is wrong with types. Value given was: ' + input
  )
}
