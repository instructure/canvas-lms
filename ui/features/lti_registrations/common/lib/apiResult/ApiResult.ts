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

import type {ZodSchema, ZodTypeDef} from 'zod'

export type ApiResult<A> =
  | {
      _type: 'success'
      data: A
    }
  | {
      _type: 'ApiParseError' | 'GenericError'
      message: string
    }
  | {
      _type: 'Exception'
      error: Error
    }

export const success = <A>(data: A): ApiResult<A> => ({
  _type: 'success',
  data,
})

export const apiParseError = (message: string): ApiResult<never> => ({
  _type: 'ApiParseError',
  message,
})

export const genericError = (message: string): ApiResult<never> => ({
  _type: 'GenericError',
  message,
})

export const exception = (error: Error): ApiResult<never> => ({
  _type: 'Exception',
  error,
})

/**
 * Takes a Zod schema and a `fetch` response
 * and returns a promise that resolves to an `ApiResult`
 * catching any errors that occur during the fetch
 * @param schema
 * @returns
 */
export const parseFetchResult =
  <O, Def extends ZodTypeDef, I>(schema: ZodSchema<O, Def, I>) =>
  (result: Promise<Response>): Promise<ApiResult<O>> => {
    return result
      .then(response => {
        if (response.ok) {
          try {
            return response.json()
          } catch (e) {
            throw new Error('Failed to parse response as JSON.')
          }
        } else {
          throw new Error('Response was not ok.')
        }
      })
      .then(schema.safeParse)
      .then(response => {
        return response.success
          ? success(response.data)
          : apiParseError(
              response.error.errors
                .map(e => {
                  if (e.code === 'invalid_type') {
                    const path = e.path.map(s => (typeof s === 'string' ? s : `[${s}]`)).join('.')
                    return `${path}: Expected: ${e.expected}, Actual: ${e.received}`
                  } else {
                    return e.message
                  }
                })
                .join('\n\n')
            )
      })
      .catch(err => {
        if (err instanceof Error) {
          return exception(err)
        } else {
          return genericError('An error occurred')
        }
      })
  }
