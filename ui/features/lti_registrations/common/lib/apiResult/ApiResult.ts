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
      /** Indicates that the backend response was parsed successfully */
      _type: 'Success'
      data: A
    }
  | {
      /** Indicates that the backend responded with a JSON value that could not be parsed */
      _type: 'ApiParseError'
      url: string
      error: ZodError<any>
    }
  | {
      /** Indicates that the backend responded with a non-JSON value */
      _type: 'InvalidJson'
      url: string
      error?: Error
    }
  | {
      /** Indicates an error response from the backend */
      _type: 'ApiError'
      status: number
      body?: unknown
    }
  | {
      _type: 'GenericError'
      message: string
    }
  | {
      _type: 'Exception'
      error: Error
    }

type UnsuccessfulApiResult = Exclude<ApiResult<unknown>, {_type: 'Success'}>
type SuccessfulApiResult<A> = Extract<ApiResult<A>, {_type: 'Success'}>

export const success = <A>(data: A): ApiResult<A> => ({
  _type: 'Success',
  data,
})

export const apiParseError = (error: ZodError, url: string): ApiResult<never> => ({
  _type: 'ApiParseError',
  url,
  error,
})

export const apiError = (status: number, body: unknown): ApiResult<never> => ({
  _type: 'ApiError',
  status,
  body,
})

export const genericError = (message: string): ApiResult<never> => ({
  _type: 'GenericError',
  message,
})

export const exception = (error: Error): ApiResult<never> => ({
  _type: 'Exception',
  error,
})

export const invalidJson = (url: string, error?: Error): ApiResult<never> => ({
  _type: 'InvalidJson',
  url,
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
          return response
            .json()
            .then(json => [response, json] as const)
            .then(([resp, json]) => [resp, schema.safeParse(json)] as const)
            .then(([resp, parsedJson]) => {
              return parsedJson.success
                ? success(parsedJson.data)
                : apiParseError(parsedJson.error, resp.url)
            })
            .catch(err => {
              return invalidJson(response.url, err instanceof Error ? err : undefined)
            })
        } else {
          return response
            .json()
            .then(body => apiError(response.status, body))
            .catch(() => apiError(response.status, undefined))
        }
      })
      .catch(err => {
        if (err instanceof Error) {
          return exception(err)
        } else {
          return genericError('An error occurred')
        }
      })
  }

export const formatApiResultError = (error: UnsuccessfulApiResult): string => {
  if (error._type === 'Exception') {
    return `${error.error.message}${error.error.stack ? `\n${error.error.stack}` : ''}`
  } else if (error._type === 'GenericError') {
    return error.message
  } else if (error._type === 'InvalidJson') {
    return `Error parsing response from ${error.url}:\nResult was not valid JSON.`
  } else if (error._type === 'ApiError') {
    return `Error from server: ${error.status} ${JSON.stringify(error.body)}`
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

/**
 * Applies a function to the data of an `ApiResult` if it is a success
 * @param result
 * @param f
 * @returns
 */
export const mapApiResult = <A, B>(result: ApiResult<A>, f: (a: A) => B): ApiResult<B> => {
  if (isSuccessful(result)) {
    return success(f(result.data))
  } else {
    return result
  }
}

/**
 * Returns true if the `ApiResult` is not a success
 * and narrows the type
 * @param result
 * @returns
 */
export const isUnsuccessful = (result: ApiResult<unknown>): result is UnsuccessfulApiResult => {
  return result._type !== 'Success'
}

/**
 * Returns true if the `ApiResult` is a success
 * and narrows the type
 * @param result
 * @returns
 */
export const isSuccessful = <A>(result: ApiResult<A>): result is SuccessfulApiResult<A> => {
  return result._type === 'Success'
}
