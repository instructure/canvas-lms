/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import * as z from 'zod'

/**
 * An error that occurred while parsing a URL search param
 */
export interface ZodParamError {
  param: string
  error: z.ZodError
}

/**
 * The result of parsing URL search params,
 * either successfully or with errors
 */
export type ParamsParseResult<A> =
  | {success: true; value: A}
  | {
      success: false
      errors: ReadonlyArray<ZodParamError>
    }

/**
 * Parses a
 * @param options
 * @returns
 */
export const parseWithZodToParamsParseResult = <A>(options: {
  schema:
    | z.ZodSchema<A, any, string | undefined>
    | z.ZodSchema<A, any, string>
    | z.ZodSchema<A, any, string[]>
  key: string
  value: string | string[] | undefined
}): ParamsParseResult<A> => {
  const {schema, key, value} = options
  const result = schema.safeParse(value)
  return result.success
    ? {success: true, value: result.data}
    : {success: false, errors: [{param: key, error: result.error}]}
}

/**
 * Formats a single error into a human-readable string
 * @param error the error to format
 * @returns a string with the error formatted
 */
export const formatSearchParamErrorMessage = (error: ZodParamError) => {
  return 'Param: ' + error.param + '\nErrors:\n  ' + error.error.format()._errors.join('\n  ')
}

/**
 * Formats a list of errors into a human-readable string
 * @param errors list of errors to format
 * @returns a string with each error formatted
 */
export const formatSearchParamErrorMessages = (errors: ReadonlyArray<ZodParamError>) =>
  errors.map(formatSearchParamErrorMessage).join('\n')
