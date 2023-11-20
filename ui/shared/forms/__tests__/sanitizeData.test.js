/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import sanitizeData from '../sanitizeData'

describe('sanitizeData()', () => {
  let data = {
    text: '<script>console.log("hi!")</script>',
  }
  const dataItems = ['text']

  const subject = () => sanitizeData(data, dataItems)

  it('sanitizes the specified fields', () => {
    expect(subject()).toMatchObject({
      text: '',
    })
  })

  const sharedExamplesForNoModifiers = () => {
    it('does not modify the field', () => {
      expect(subject()).toMatchObject(data)
    })
  }

  describe('when partial sanitization is needed', () => {
    beforeEach(
      () => (data = {text: "<div>Don't remove me <script>console.log('remove me')</script></div>"})
    )

    it('only removes the unsafe elements', () => {
      expect(subject()).toMatchObject({text: "<div>Don't remove me</div>"})
    })
  })

  describe('when no sanitization is needed', () => {
    beforeEach(() => (data = {text: '<h2>hi!</h2>'}))

    sharedExamplesForNoModifiers()
  })

  describe('when the specified field is blank', () => {
    beforeEach(() => (data = {foo: 'bar'}))

    sharedExamplesForNoModifiers()
  })

  describe('with elements/attributes that are disallowed by default', () => {
    beforeEach(() => {
      data = {
        text: `
          <iframe
            style="width: 800px; height: 600px;"
            title="It's amazing"
            src="/"
            width="800"
            height="600"
            allowfullscreen="allowfullscreen"
            webkitallowfullscreen="webkitallowfullscreen"
            mozallowfullscreen="mozallowfullscreen"
            allow="geolocation *; microphone *; camera *; midi *; encrypted-media *; autoplay *; clipboard-write *; display-capture *">
          </iframe>
        `,
      }
    })

    it('allows the elements', () => {
      expect(subject().text).toMatchInlineSnapshot(`
        " <iframe style="width: 800px; height: 600px;" title="It's amazing" src="/" width="800" height="600" allowfullscreen="allowfullscreen" webkitallowfullscreen="webkitallowfullscreen" mozallowfullscreen="mozallowfullscreen" allow="geolocation *; microphone *; camera *; midi *; encrypted-media *; autoplay *; clipboard-write *; display-capture *">
                  </iframe> "
      `)
    })
  })
})
