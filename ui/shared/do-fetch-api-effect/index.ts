/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import parseLinkHeader, {type Links} from '@canvas/parse-link-header'
import {defaultFetchOptions} from '@canvas/util/xhr'
import {toQueryString} from '@instructure/query-string-encoding'
import type {QueryParameterRecord} from '@instructure/query-string-encoding/index.d'
import z from 'zod'

const jsonRegEx = /^application\/json/i

function constructRelativeUrl({
  path,
  params,
}: {
  path: string
  params: QueryParameterRecord
}): string {
  const queryString = toQueryString(params)
  if (queryString.length === 0) return path
  const separator = path.includes('?') ? '&' : '?' // in case path already contains query parms
  return `${path}${separator}${queryString}`
}

// https://fetch.spec.whatwg.org/#requestinit
interface RequestInit {
  signal?: AbortSignal
  cache?: RequestCache
}

export type DoFetchApiOpts = {
  path: string
  method?: string
  headers?: {[k: string]: string} | Headers
  params?: QueryParameterRecord
  body?: string | FormData | object
  fetchOpts?: RequestInit
  signal?: AbortSignal
  includeCSRFToken?: boolean
}

export type DoFetchApiResults<T> = {
  text: string
  json?: T
  response: Response
  link?: Links
}

export class FetchApiError extends Error {
  response: Response

  constructor(message: string, response: Response) {
    super(message)
    this.response = response
  }
}

export default async function doFetchApi<T = unknown>({
  path,
  method = 'GET',
  headers = {}, // can be object or Headers
  params = {},
  body,
  signal,
  fetchOpts = {}, // do not specify headers in fetchOpts.headers ... use headers instead
  includeCSRFToken = true,
}: DoFetchApiOpts): Promise<DoFetchApiResults<T>> {
  const {credentials, headers: defaultHeaders} = defaultFetchOptions()
  const suppliedHeaders = new Headers(headers)
  const fetchHeaders = new Headers(defaultHeaders)

  suppliedHeaders.forEach((v, k) => fetchHeaders.set(k, v))

  if (!includeCSRFToken) {
    // If we are not including the CSRF token, we need to remove it from the headers
    // and also remove the X-Requested-With header because it forces an OPTIONS request
    fetchHeaders.delete('X-Requested-With')
    fetchHeaders.delete('X-CSRF-Token')
  }

  // properly encode and set the content type if a body was given
  if (body) {
    if (body instanceof FormData) {
      fetchHeaders.delete('Content-Type') // must let the browser handle it
    } else if (typeof body !== 'string') {
      body = JSON.stringify(body)
      fetchHeaders.set('Content-Type', 'application/json')
    }
  }

  const url = constructRelativeUrl({path, params})
  const response = await fetch(url, {
    body,
    method,
    ...fetchOpts,
    headers: fetchHeaders,
    signal,
    credentials,
  })
  if (!response.ok) {
    throw new FetchApiError(
      `doFetchApi received a bad response: ${response.status} ${response.statusText}`,
      response,
    )
  }
  const linkHeader = response.headers.get('Link')
  const contentType = response.headers.get('Content-Type') ?? ''
  const link = (linkHeader && parseLinkHeader(linkHeader)) || undefined
  const text = await response.text()
  if (text.length > 0 && jsonRegEx.test(contentType)) {
    const json = JSON.parse(text) as T
    return {json, response, link, text}
  }
  return {response, link, text}
}

export type SafelyFetchResults<T> = {
  json?: T
  response: Response
  link?: Links
}

/**
 * Fetch data from a API endpoint (that returns JSON!) and validate the response against a schema, but only in non-production environments.
 *
 * @deprecated Please use `doFetchWithSchema` instead. This function only validates the response in non-production environments,
 * leading to subtle issues in production where the schema validation or transformation is not applied.
 * @param param0 Arguments to pass along to doFetchApi
 * @param schema The Zod schema to validate the response against, but only in non-production environments.
 * @returns
 */
export async function safelyFetch<T = unknown>(
  {path, method = 'GET', headers = {}, params = {}, signal, body}: DoFetchApiOpts,
  schema: z.Schema<T>,
): Promise<SafelyFetchResults<T>> {
  if (!schema) {
    throw new Error('safelyFetch requires a schema')
  }

  const {json, response, link} = await doFetchApi<T>({path, method, headers, params, signal, body})

  if (process.env.NODE_ENV !== 'production') {
    try {
      schema.parse(json)
    } catch (err) {
      // eslint-disable-next-line import/no-named-as-default-member
      if (err instanceof z.ZodError) {
        console.group(`Zod parsing error for ${path}`)
        for (const issue of err.issues) {
          console.error(`Error at ${issue.path.join('.')} - ${issue.message}`)
        }
        console.groupEnd()

        throw err
      }
    }
  }

  return {json, response, link}
}

export type DoFetchWithSchemaResults<T = unknown> = {
  json: T
} & DoFetchApiResults<T>

/**
 * Fetch data from a API endpoint (that returns JSON!) and validate the response against a schema.
 * If the response is not valid according to the schema, an error will be thrown.
 * Especially useful when used together with TanStack Query to automatically handle errors for you.
 *
 * This function will always validate the response against the schema, regardless of the environment. `safelyFetch`
 * only does schema validation in non-production environments and should thus not be used in new code.
 *
 * @param opts The arguments to pass to doFetchApi
 * @param schema The schema to validate the response against
 * @returns A promise that resolves to the fetched results. If the response is not valid according to the schema, an error will be thrown.
 * @throws {ZodError} If the response is not valid according to the schema
 * @throws {SyntaxError} If the response is not valid JSON
 * @throws {FetchApiError} If the fetch request fails (e.g., network error, non-2xx status code)
 * @throws {Error} For all other possible errors.
 */
export async function doFetchWithSchema<Output, Def extends z.ZodTypeDef, Input>(
  opts: DoFetchApiOpts,
  schema: z.Schema<Output, Def, Input>,
): Promise<DoFetchWithSchemaResults<Output>> {
  const result = await doFetchApi(opts)
  const parsed = schema.parse(result.json)
  return {
    ...result,
    json: parsed,
  }
}
