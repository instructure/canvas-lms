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

import * as URI from 'uri-js'

/**
 * Attempts to build a URL from the given string, and returns null if it is not a valid URL, rather than
 * throwing an exception, as the URL constructor does.
 */
export function parseUrlOrNull(url: string | null | undefined, base?: string | URL): URL | null {
  if (!url) return null

  try {
    return new URL(url, base)
  } catch (e) {
    return null
  }
}

export function relativizeUrl(url: string): string {
  const parsed = URI.parse(url)
  delete parsed.scheme
  delete parsed.userinfo
  delete parsed.host
  delete parsed.port
  return URI.serialize(parsed)
}

/**
 * Converts the given URL into a relative URL if it meets the following criteria:
 * - is parsable by the browser URL class
 * - has the HTTP or HTTPS protocol
 * - has the same hostname as the given origin
 *
 * Note: This will relativize URLs where the ports don't match. This is intentional, as ports really shouldn't
 * matter for RCE HTTP content, and it can solve issues where an extraneous port is added (e.g. :80 on an http url)
 * or when running locally and the port is different. There isn't a security issue because the user could just manually
 * put in the transformed content anyways.
 *
 * @param inputUrlStr URL to relativize
 * @param origin Origin to check for
 */
export function relativeHttpUrlForHostname<TInput extends string | null | undefined>(
  inputUrlStr: TInput,
  origin: string
): TInput {
  if (inputUrlStr == null || inputUrlStr === '') {
    return inputUrlStr
  }

  if (!inputUrlStr?.match(/^https?:/i) || !origin?.match(/^https?:/i)) {
    // Already relative or not a http/https protocol url
    return inputUrlStr
  }

  const url = parseUrlOrNull(inputUrlStr)
  if (url == null) {
    return inputUrlStr
  }

  // Handle the simple case of origins matching. Note that the parsed URL will always have a lowercase origin
  // new URL("hTTps://CaNvAs.CoM").origin === 'https://canvas.com'
  if (url.origin === origin.toLowerCase()) {
    return relativizeUrl(inputUrlStr) as TInput
  }

  // Handle the more complex case of hostname/port matching
  const originUrl = parseUrlOrNull(origin)
  const originHostname = originUrl?.hostname

  // Port checks are only needed if the port is not the default port for http or https.
  // If the port isn't an http port, then we don't want equivalence, especially for local origins,
  // since you might be running canvas on "localhost:3000" and some LTI tool on "localhost:4000"
  // But elsewhere, "http://canvas.com:80" and "http://canvas.com" are equivalent
  const urlUsesHttpPort = url.port === '80' || url.port === '443' || url.port === ''
  const originUsesHttpPort =
    originUrl == null ||
    originUrl?.port === '80' ||
    originUrl?.port === '443' ||
    originUrl?.port === ''

  const portCheckNeeded = !(urlUsesHttpPort && originUsesHttpPort)

  if (portCheckNeeded && originUrl?.port !== url?.port) {
    return inputUrlStr
  }

  if (url.hostname === originHostname?.toLowerCase()) {
    return relativizeUrl(inputUrlStr) as TInput
  } else {
    return inputUrlStr
  }
}

/**
 * Adds a record of query parameters to a URL. null or undefined values in the record are ignored.
 *
 * - Relative URLs are supported.
 * - Non-parsable URLs will return null.
 *
 * @param inputUrlStr The URL string to parse
 * @param queryParams A record containing the query parameters to add
 */
export function addQueryParamsToUrl(
  inputUrlStr: string | null | undefined,
  queryParams: Record<string, string | null | undefined>
): string | null {
  if (inputUrlStr == null) {
    return null
  }

  const paramEntries = Object.entries(queryParams)

  if (paramEntries.length === 0) {
    return inputUrlStr
  }

  const parsedUrl = URI.parse(inputUrlStr)
  if (parsedUrl == null) {
    return null
  }

  const searchParams = new URLSearchParams(parsedUrl.query ?? '')

  for (const [paramName, paramValue] of paramEntries) {
    if (paramValue != null) {
      searchParams.set(paramName, paramValue)
    }
  }

  parsedUrl.query = searchParams.toString()

  return URI.serialize(parsedUrl)
}
