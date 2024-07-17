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

import type {ZodSchema, ZodTypeDef, ZodError} from 'zod'

export type ApiResult<A> =
  | {
      _type: 'success'
      data: A
    }
  | {
      _type: 'ApiParseError'
      url: string
      error: ZodError<any>
    }
  | {
      _type: 'GenericError'
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

export const apiParseError = (error: ZodError, url: string): ApiResult<never> => ({
  _type: 'ApiParseError',
  url,
  error,
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
            return response.json().then(json => [response, json] as const)
          } catch (e) {
            throw new Error('Failed to parse response as JSON.')
          }
        } else {
          throw new Error('Response was not ok.')
        }
      })
      .then(([resp, json]) => [resp, schema.safeParse(json)] as const)
      .then(([resp, parsedJson]) => {
        return parsedJson.success
          ? success(parsedJson.data)
          : apiParseError(parsedJson.error, resp.url)
      })
      .catch(err => {
        if (err instanceof Error) {
          return exception(err)
        } else {
          return genericError('An error occurred')
        }
      })
  }

export const formatApiResultError = (
  error: Exclude<ApiResult<unknown>, {_type: 'success'}>
): string => {
  if (error._type === 'Exception') {
    return `${error.error.message}${error.error.stack ? `\n${error.error.stack}` : ''}`
  } else if (error._type === 'GenericError') {
    return error.message
  } else {
    const messages = error.error.errors
      .map(issue => {
        return `${issue.path.map(p => (typeof p === 'number' ? `[${p}]` : p)).join('.')} ${
          issue.code
        }: ${issue.message}`
      })
      .join('\n')
    return `Error parsing response from ${error.url}:\n${messages}`
  }
}
