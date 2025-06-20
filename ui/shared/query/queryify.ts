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

type Querify<F extends (...args: any[]) => any> = (p: {
  queryKey: [string, ...Parameters<F>]
}) => ReturnType<F>

/**
 * Converts a function that takes parameters into a function that
 * can be used with react-query, neatly lining up the parameters
 * with how react-query passes the queryKey into the query function.
 *
 * @example
 * ```ts
 * declare const searchCourses: (searchTerm: string) => Promise<Course[]>
 *
 * useQuery({
 *   queryKey: ['searchCourses', "Math"],
 *   queryFn: queryify(fetchContextSearch),
 * })
 * ```
 *
 * @param f The function to convert
 * @returns A function that takes an object with a queryKey property
 */
export const queryify = <F extends (...args: any[]) => any>(f: F): Querify<F> => {
  return ({queryKey}) => {
    const [_key, ...rest] = queryKey
    return f(...rest)
  }
}
