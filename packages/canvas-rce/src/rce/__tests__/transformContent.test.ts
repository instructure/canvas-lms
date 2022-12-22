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
  attributeNamesToRemove,
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

  it('should relativize urls', () => {
    expect(
      transformRceContentForEditing(
        '<img src="https://canvas.com/image.jpg">' +
          '<img random="https://canvas.com/image.jpg">' +
          '<img src="https://othercanvas.com/image.jpg">' +
          '<div>' +
          '<img src="https://canvas.com/image.jpg">' +
          '<img src="https://othercanvas.com/image.jpg">' +
          '</div>',
        defaultOptions
      )
    ).toEqual(
      '<img src="/image.jpg">' +
        '<img random="https://canvas.com/image.jpg">' +
        '<img src="https://othercanvas.com/image.jpg">' +
        '<div>' +
        '<img src="/image.jpg">' +
        '<img src="https://othercanvas.com/image.jpg">' +
        '</div>'
    )
  })

  it('should remove unnecessary attributes', () => {
    const elements = [
      {value: 'iframe', shouldTransform: true},
      {value: 'img', shouldTransform: true, selfClosing: true},
      {value: 'embed', shouldTransform: true, selfClosing: true},
    ]

    const attributes = [
      ...attributeNamesToRemove.map(value => ({
        value,
        shouldRemove: true,
      })),
      {value: 'random', shouldRemove: false},
    ]

    elements.forEach(element => {
      attributes.forEach(attribute => {
        const elementWithAttribute = element.selfClosing
          ? `<${element.value} ${attribute.value}="whatever">`
          : `<${element.value} ${attribute.value}="whatever"></${element.value}>`
        const withAttributeHtml = `${elementWithAttribute}<div>${elementWithAttribute}</div>`

        const elementWithoutAttribute = element.selfClosing
          ? `<${element.value}>`
          : `<${element.value}></${element.value}>`
        const withoutAttributeHtml = `${elementWithoutAttribute}<div>${elementWithoutAttribute}</div>`

        const transformedHtml = transformRceContentForEditing(withAttributeHtml, defaultOptions)

        if (attribute.shouldRemove) {
          expect(transformedHtml).toEqual(withoutAttributeHtml)
        } else {
          expect(transformedHtml).toEqual(withAttributeHtml)
        }
      })
    })
  })
})
