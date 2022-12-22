/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import {parseUrlOrNull, relativeHttpUrlForHostname} from '../url-util'

describe('parseUrlOrNull', () => {
  it('should parse a valid url', () => {
    expect(parseUrlOrNull('https://foobar.local/123')?.toString()).toEqual(
      'https://foobar.local/123'
    )
  })

  it('should parse a valid url with an origin', () => {
    expect(parseUrlOrNull('/123', 'https://foobar.local')?.toString()).toEqual(
      'https://foobar.local/123'
    )
  })

  it('should handle falsey values', () => {
    expect(parseUrlOrNull(null)).toEqual(null)
  })

  it('should handle invalid URLs', () => {
    expect(parseUrlOrNull('!@#!@#')).toEqual(null)
  })
})

describe('relativeHttpUrlForHostname', () => {
  it('should only relativize urls when appropriate', () => {
    const canvasOrigins = [
      {value: 'HTTP://CANVAS.COM', shouldTransform: true},
      {value: 'HTTPS://CANVAS.COM', shouldTransform: true},
      {value: 'http://canvas.com', shouldTransform: true},
      {value: 'https://canvas.com', shouldTransform: true},
      {value: 'http://canvas.com:80', shouldTransform: true},
      {value: 'https://canvas.com:443', shouldTransform: true},
      {value: 'http://canvas.com:443', shouldTransform: true},
      {value: 'https://canvas.com:80', shouldTransform: true},
      {value: 'http://canvas.com:1234', shouldTransform: true},
    ]

    const urlOrigins = [
      {value: 'HTTP://CANVAS.COM', shouldTransform: true},
      {value: 'HTTPS://CANVAS.COM', shouldTransform: true},

      {value: 'http://canvas.com', shouldTransform: true},
      {value: 'https://canvas.com', shouldTransform: true},
      {value: 'ftp://canvas.com', shouldTransform: false},

      {value: 'http://canvas.com:80', shouldTransform: true},
      {value: 'https://canvas.com:443', shouldTransform: true},
      {value: 'http://canvas.com:443', shouldTransform: true},
      {value: 'https://canvas.com:80', shouldTransform: true},
      {value: 'http://canvas.com:1234', shouldTransform: true},
      {value: 'https://canvas.com:1234', shouldTransform: true},

      {value: 'http://other.canvas.com', shouldTransform: false},
      {value: 'https://other.canvas.com', shouldTransform: false},
      {value: 'https://google.com', shouldTransform: false},
      {value: 'http://nowhere.com', shouldTransform: false},
    ]

    const paths = [
      {value: '/other-page', shouldTransform: true},
      {value: '/avocado.jpg', shouldTransform: true},
      {value: '!@#$%^', shouldTransform: false},
    ]

    const elements = [
      {value: 'iframe', shouldTransform: true},
      {value: 'img', shouldTransform: true, selfClosing: true},
      {value: 'embed', shouldTransform: true, selfClosing: true},
    ]

    canvasOrigins.forEach(canvasOrigin => {
      urlOrigins.forEach(urlOrigin => {
        paths.forEach(path => {
          elements.forEach(element => {
            const shouldTransform = [canvasOrigin, urlOrigin, path, element].every(
              it => it.shouldTransform
            )

            const absoluteUrl = `${urlOrigin.value}${path.value}`
            const relativeUrl = path.value

            const transformedUrl = relativeHttpUrlForHostname(absoluteUrl, canvasOrigin.value)
            const expectedUrl = shouldTransform ? relativeUrl : absoluteUrl

            expect(transformedUrl).toEqual(expectedUrl)
          })
        })
      })
    })
  })
})
