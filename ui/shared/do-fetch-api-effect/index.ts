/* eslint-disable no-console */
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

import getCookie from '@instructure/get-cookie'
import parseLinkHeader, {type Links} from '@canvas/parse-link-header'
import {defaultFetchOptions} from '@canvas/util/xhr'
import {toQueryString} from '@canvas/query-string-encoding'
import type {QueryParameterRecord} from '@canvas/query-string-encoding'
import z from 'zod'

type RequestCredentials = 'include' | 'omit' | 'same-origin'

function constructRelativeUrl({
  path,
  params,
}: {
  path: string
  params: QueryParameterRecord
}): string {
  const queryString = toQueryString(params)
  if (queryString.length === 0) return path
  return `${path}?${queryString}`
}

// https://fetch.spec.whatwg.org/#requestinit
interface RequestInit {
  signal?: AbortSignal
}

export type DoFetchApiOpts = {
  path: string
  method?: string
  headers?: {[k: string]: string}
  params?: QueryParameterRecord
  // eslint-disable-next-line no-undef
  body?: BodyInit
  fetchOpts?: RequestInit
  signal?: AbortSignal
}

export type DoFetchApiResults<T> = {
  json?: T
  response: Response
  link?: Links
}

export default async function doFetchApi<T = unknown>({
  path,
  method = 'GET',
  headers = {},
  params = {},
  body,
  signal,
  fetchOpts = {}, // we do not deep-merge fetchOptions.headers
}: DoFetchApiOpts): Promise<DoFetchApiResults<T>> {
  const finalFetchOptions = {...defaultFetchOptions()}
  finalFetchOptions.headers['X-CSRF-Token'] = getCookie('_csrf_token')

  if (body && !(body instanceof FormData) && !(typeof body === 'string')) {
    body = JSON.stringify(body)
    finalFetchOptions.headers['Content-Type'] = 'application/json'
  }
  Object.assign(finalFetchOptions.headers, headers)
  Object.assign(finalFetchOptions, fetchOpts)

  const url = constructRelativeUrl({path, params})
  const response = await fetch(url, {
    body,
    method,
    ...finalFetchOptions,
    signal,
    credentials: finalFetchOptions.credentials as RequestCredentials,
  })
  if (!response.ok) {
    const err = new Error(
      `doFetchApi received a bad response: ${response.status} ${response.statusText}`
    )
    Object.assign(err, {response}) // in case anyone wants to check it for something
    throw err
  }
  const linkHeader = response.headers.get('Link')
  const link = (linkHeader && parseLinkHeader(linkHeader)) || undefined
  const text = await response.text()
  const json = text.length > 0 ? (JSON.parse(text) as T) : undefined
  return {json, response, link}
}

export type SafelyFetchResults<T> = {
  json?: T
  response: Response
  link?: Links
}

export async function safelyFetch<T = unknown>(
  {path, method = 'GET', headers = {}, params = {}, signal, body}: DoFetchApiOpts,
  schema: z.Schema<T>
): Promise<SafelyFetchResults<T>> {
  if (!schema) {
    throw new Error('safelyFetch requires a schema')
  }

  const {json, response, link} = await doFetchApi<T>({path, method, headers, params, signal, body})

  if (process.env.NODE_ENV !== 'production') {
    try {
      schema.parse(json)
    } catch (err) {
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
