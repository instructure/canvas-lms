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

import $ from 'jquery'
import getCookie from '@instructure/get-cookie'
import parseLinkHeader from 'parse-link-header'
import {defaultFetchOptions} from '@instructure/js-utils'

function constructRelativeUrl({path, params}: {path: string; params: {[k: string]: any}}) {
  const queryString = $.param(params)
  if (!queryString.length) return path
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
  params?: {[k: string]: any}
  body?: any
  fetchOpts?: RequestInit
}

export type DoFetchApiResults<T> = {
  json?: T
  response: Response
  link?: parseLinkHeader.Links
}

// NOTE: we do NOT deep-merge customFetchOptions.headers, they should be passed
// in the headers arg instead.
export default async function doFetchApi<T = any>({
  path,
  method = 'GET',
  headers = {},
  params = {},
  body,
  fetchOpts = {}
}: DoFetchApiOpts): Promise<DoFetchApiResults<T>> {
  const finalFetchOptions = {...defaultFetchOptions}
  finalFetchOptions.headers['X-CSRF-Token'] = getCookie('_csrf_token')

  if (body && typeof body !== 'string') {
    body = JSON.stringify(body)
    finalFetchOptions.headers['Content-Type'] = 'application/json'
  }
  Object.assign(finalFetchOptions.headers, headers)
  Object.assign(finalFetchOptions, fetchOpts)

  const url = constructRelativeUrl({path, params})
  const response = await fetch(url, {body, method, ...finalFetchOptions})
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
