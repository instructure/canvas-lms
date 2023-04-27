// @ts-nocheck
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

import spacing from '../spacing'

describe('spacing()', () => {
  let content

  const parser = new DOMParser()
  const subject = () => spacing(content, parser).replace(/\s/g, '')

  describe('when the entire body has no text', () => {
    beforeEach(() => {
      content = '<p><span class="math_equation_latex"></span></p>'
    })

    it('returns a break', () => {
      expect(subject()).toEqual('<br/>')
    })
  })

  describe('when the entire body has no text, but does have whitespace', () => {
    beforeEach(() => {
      content = `
        <p>

          <span class="math_equation_latex"></span>
        </p>
      `
    })

    it('returns a paragraph with the given whitespace', () => {
      expect(subject()).toEqual('<p></p>')
    })
  })

  describe('when the body does have text', () => {
    describe('when the math element has no text', () => {
      beforeEach(() => {
        content = `
          <div>
            keep me!
            <p><span class="math_equation_latex"></span></p>
          </div>
        `
      })

      it('removes the math element', () => {
        expect(subject()).toEqual('<div>keepme!</div>')
      })
    })

    describe('when the math element does have text', () => {
      beforeEach(() => {
        content = `
          <div>
            keep me!
            <p><span class="math_equation_latex">text!</span></p>
          </div>
        `
      })

      it('does not remove the math element', () => {
        expect(subject()).toEqual(
          '<div>keepme!<p><spanclass="math_equation_latex">text!</span></p></div>'
        )
      })
    })

    describe('when there is no math element', () => {
      beforeEach(() => {
        content = `
          <div>
            keep me!
          </div>
        `
      })

      it('returns the content without change', () => {
        expect(subject()).toEqual('<div>keepme!</div>')
      })
    })
  })

  describe('when the content is empty', () => {
    beforeEach(() => (content = ''))

    it('returns an empty string', () => {
      expect(subject()).toEqual('')
    })
  })

  describe('when the content is missing matching tags', () => {
    beforeEach(() => {
      content = `
          <div>
            <span>
              keep me!
        `
    })

    it('adds a matching tag', () => {
      expect(subject()).toEqual('<div><span>keepme!</span></div>')
    })
  })
})
