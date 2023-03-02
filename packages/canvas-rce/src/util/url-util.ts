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
 * @param inputValue URL to relativize
 * @param origin Origin to check for
 */
export function relativeHttpUrlForHostname<TInput extends string | null | undefined>(
  inputValue: TInput,
  origin: string
): TInput {
  if (!inputValue) {
    return inputValue
  }

  if (!inputValue?.match(/^https?:/i)) {
    // Already relative or not a http/https protocol url
    return inputValue
  }

  const url = parseUrlOrNull(inputValue)
  if (!url) {
    return inputValue
  }

  // Handle the simple case of origins matching
  if (url.origin === origin.toLowerCase()) {
    return url.toString().substring(url.origin.length) as TInput
  }

  // Handle the more complex case of hostname/port matching
  const originHostname = parseUrlOrNull(origin)?.hostname

  if (url.hostname.toLowerCase() === originHostname?.toLowerCase()) {
    return url.toString().substring(url.origin.length) as TInput
  } else {
    return inputValue
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
