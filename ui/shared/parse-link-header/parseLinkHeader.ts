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

// based on https://github.com/thlorenz/parse-link-header/blob/master/index.js (MIT)

type LinkInfo = {
  [key: string]: string
}

function parseQueryParams(linkUrl: string): {[key: string]: string} {
  const queryParams: {[key: string]: string} = {}
  const urlParts = linkUrl.split('?')
  if (urlParts.length > 1) {
    urlParts[1].split('&').forEach(param => {
      const [key, value] = param.split('=')
      queryParams[key] = decodeURIComponent(value)
    })
  }
  return queryParams
}

function parseLink(link: string): LinkInfo | null {
  try {
    const linkMatch = link.match(/<([^>]*)>\s*(.*)/)
    if (!linkMatch) {
      return null
    }

    const [, linkUrl, partsString] = linkMatch
    const parts = partsString.split(';').map(part => part.trim())

    const info: LinkInfo = {url: linkUrl}

    parts.forEach(part => {
      const partMatch = part.match(/(.+)\s*=\s*"?([^"]+)"?/)
      if (partMatch) {
        const [, key, value] = partMatch
        info[key.trim()] = value.trim()
      }
    })

    return {...parseQueryParams(linkUrl), ...info}
  } catch (e) {
    return null
  }
}

function hasRel(x: LinkInfo | null): x is LinkInfo {
  return x !== null && 'rel' in x
}

function intoRels(acc: {[rel: string]: LinkInfo}, x: LinkInfo): {[rel: string]: LinkInfo} {
  x.rel.split(/\s+/).forEach(rel => {
    const {...rest} = x
    acc[rel] = rest
  })

  return acc
}

const PARSE_LINK_HEADER_MAXLEN = 2000
const PARSE_LINK_HEADER_THROW_ON_MAXLEN_EXCEEDED =
  process.env.PARSE_LINK_HEADER_THROW_ON_MAXLEN_EXCEEDED != null

function checkHeader(linkHeader: string | undefined): boolean {
  if (!linkHeader) return false

  if (linkHeader.length > PARSE_LINK_HEADER_MAXLEN) {
    if (PARSE_LINK_HEADER_THROW_ON_MAXLEN_EXCEEDED) {
      throw new Error(
        `Input string too long, it should be under ${PARSE_LINK_HEADER_MAXLEN} characters.`
      )
    } else {
      return false
    }
  }
  return true
}

export default function parseLinkHeader(linkHeader: string): {[rel: string]: LinkInfo} | null {
  if (!checkHeader(linkHeader)) return null

  return linkHeader
    .split(/,\s*(?=<)/)
    .map(parseLink)
    .filter(hasRel)
    .reduce(intoRels, {})
}
