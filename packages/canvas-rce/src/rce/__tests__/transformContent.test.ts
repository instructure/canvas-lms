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

import {
  transformRceContentForEditing,
  TransformRceContentForEditingOptions,
} from '../transformContent'

describe('transformRceContentForEditing', () => {
  const defaultOptions: TransformRceContentForEditingOptions = {
    origin: 'http://canvas.com',
  }

  it('should not modify falsey inputs', () => {
    expect(transformRceContentForEditing(null, defaultOptions)).toEqual(null)
    expect(transformRceContentForEditing(undefined, defaultOptions)).toEqual(undefined)
    expect(transformRceContentForEditing('', defaultOptions)).toEqual('')
  })

  it('should handle a real-world LTI URL', () => {
    const url =
      '/courses/961/external_tools/retrieve?display=in_rce&amp;url=https%3A%2F%2Faware.instructuremedia.com%2Flti%2Flaunch%3Fcustom_arc_launch_type%3Dembed%26custom_arc_media_id%3D41c61c58-4182-458c-84b4-d0cdc98d331e-21'

    expect(
      transformRceContentForEditing(
        `<iframe src="${defaultOptions.origin + url}"></iframe>`,
        defaultOptions
      )
    ).toEqual(`<iframe src="${url}"></iframe>`)
  })

  it('replaces `borderless` with `in_rce` for LTI launch URLs', () => {
    const url =
      '/courses/961/external_tools/retrieve?display=borderless&amp;url=https%3A%2F%2Faware.instructuremedia.com%2Flti%2Flaunch%3Fcustom_arc_launch_type%3Dembed%26custom_arc_media_id%3D41c61c58-4182-458c-84b4-d0cdc98d331e-21'

    expect(transformRceContentForEditing(`<iframe src="${url}"></iframe>`, defaultOptions)).toEqual(
      `<iframe src="${url.replace('borderless', 'in_rce')}"></iframe>`
    )
  })

  it('should handle content with extraneous <html> and <body> elements', () => {
    expect(
      transformRceContentForEditing(
        `<title>this is great</title><body>first body!</body><html><body> and now, lol, second body</body></html><html><html>More stuff </body><a href="http://canvas.com/lol-what?">canvas.com</a>`,
        defaultOptions
      )
    ).toEqual(
      `<title>this is great</title>first body! and now, lol, second bodyMore stuff <a href="/lol-what?">canvas.com</a>`
    )
  })

  it('should relativize urls', () => {
    expect(
      transformRceContentForEditing(
        '<img src="https://canvas.com/image.jpg?something=x">' +
          '<img random="https://canvas.com/image.jpg">' +
          '<img src="https://othercanvas.com/image.jpg">' +
          '<div>' +
          '<img src="https://canvas.com/image.jpg">' +
          '<img src="https://othercanvas.com/image.jpg">' +
          '</div>',
        defaultOptions
      )
    ).toEqual(
      '<img src="/image.jpg?something=x">' +
        '<img random="https://canvas.com/image.jpg">' +
        '<img src="https://othercanvas.com/image.jpg">' +
        '<div>' +
        '<img src="/image.jpg">' +
        '<img src="https://othercanvas.com/image.jpg">' +
        '</div>'
    )
  })

  it('should remove unnecessary attributes', () => {
    const options = {origin: 'http://canvas.com'}

    ;['data-api-endpoint', 'data-api-returntype'].forEach(attr => {
      // Non-self-closing tags
      ;['iframe', 'div', 'other'].forEach(tag => {
        expect(
          transformRceContentForEditing(
            `<${tag} ${attr}="whatever"></${tag}><div><${tag} ${attr}="whatever"></${tag}></div>`,
            options
          )
        ).toEqual(`<${tag}></${tag}><div><${tag}></${tag}></div>`)
      })

      // Self-closing tags
      ;['embed', 'img'].forEach(tag => {
        expect(
          transformRceContentForEditing(
            `<${tag} ${attr}="whatever"><div><${tag} ${attr}="whatever"></div>`,
            options
          )
        ).toEqual(`<${tag}><div><${tag}></div>`)
      })
    })
  })

  it('should NOT remove other attributes', () => {
    const options = {origin: 'http://canvas.com'}

    ;['alt', 'style', 'title', 'class'].forEach(attr => {
      // Non-self-closing tags
      ;['iframe', 'div', 'other'].forEach(tag => {
        expect(
          transformRceContentForEditing(
            `<${tag} ${attr}="whatever"></${tag}><div><${tag} ${attr}="whatever"></${tag}></div>`,
            options
          )
        ).toEqual(
          `<${tag} ${attr}="whatever"></${tag}><div><${tag} ${attr}="whatever"></${tag}></div>`
        )
      })

      // Self-closing tags
      ;['embed', 'img'].forEach(tag => {
        expect(
          transformRceContentForEditing(
            `<${tag} ${attr}="whatever"><div><${tag} ${attr}="whatever"></div>`,
            options
          )
        ).toEqual(`<${tag} ${attr}="whatever"><div><${tag} ${attr}="whatever"></div>`)
      })
    })
  })
})
