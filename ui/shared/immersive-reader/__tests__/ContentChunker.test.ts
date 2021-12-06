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

import ContentChunker from '../ContentChunker'

describe('ContentChunker', () => {
  let options = {}
  let chunker = new ContentChunker(options)

  describe('chunk()', () => {
    let content = `
      <div>
        Some simple content
        <img src="something"
          class="MathJax_SVG"
          data-mathml="<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>"
        />
        Some post math content
      </div>
    `

    const subject = () => chunker.chunk(content)

    it('creates chunks of HTML and MathML', () => {
      expect(subject()).toMatchObject([
        {
          content: '<div>\n        Some simple content\n        ',
          mimeType: 'text/html'
        },
        {
          content: '<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>',
          mimeType: 'application/mathml+xml'
        },
        {
          content: 'Some post math content\n      \n    ',
          mimeType: 'text/html'
        }
      ])
    })

    describe('with content set to ""', () => {
      beforeEach(() => (content = ''))

      it('chunks the content', () => {
        expect(subject()).toMatchObject([{content: '', mimeType: 'text/html'}])
      })
    })

    describe('with no math', () => {
      beforeEach(() => {
        content = `
          <div>
            Hello!
            <img src="something" alt="something" />
          </div>
        `
      })

      it('returns a single chunk of content', () => {
        expect(subject()).toMatchObject([
          {
            content:
              '<div>\n' +
              '            Hello!\n' +
              '            <img src="something" alt="something">\n' +
              '          </div>\n' +
              '        ',
            mimeType: 'text/html'
          }
        ])
      })
    })

    describe('with multiple adjacent math chunks', () => {
      beforeEach(() => {
        content = `
          <div>
            Pre-math
            <img src="something" class="MathJax_SVG" data-mathml="<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>" />
            <img src="something" class="MathJax_SVG" data-mathml="<mrow><apply><minus/><ci>b</ci><ci>c</ci></apply></mrow>"/>
            Post-math
          </div>
        `
      })

      it('returns a chunk for each piece of math', () => {
        expect(subject()).toMatchObject([
          {
            content: '<div>\n            Pre-math\n            ',
            mimeType: 'text/html'
          },
          {
            content: '<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>',
            mimeType: 'application/mathml+xml'
          },
          {content: '', mimeType: 'text/html'},
          {
            content: '<mrow><apply><minus/><ci>b</ci><ci>c</ci></apply></mrow>',
            mimeType: 'application/mathml+xml'
          },
          {content: 'Post-math\n          \n        ', mimeType: 'text/html'}
        ])
      })
    })

    describe('with multiple non-adjacent math chunks', () => {
      beforeEach(() => {
        content = `
          <div>
            Pre-math
            <img src="something" class="MathJax_SVG" data-mathml="<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>" />
            Between Math
            <img src="something" class="MathJax_SVG" data-mathml="<mrow><apply><minus/><ci>b</ci><ci>c</ci></apply></mrow>"/>
            Post-math
          </div>
        `
      })

      it('returns a chunk for each html/math piece', () => {
        expect(subject()).toMatchObject([
          {
            content: '<div>\n            Pre-math\n            ',
            mimeType: 'text/html'
          },
          {
            content: '<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>',
            mimeType: 'application/mathml+xml'
          },
          {content: 'Between Math\n            ', mimeType: 'text/html'},
          {
            content: '<mrow><apply><minus/><ci>b</ci><ci>c</ci></apply></mrow>',
            mimeType: 'application/mathml+xml'
          },
          {content: 'Post-math\n          \n        ', mimeType: 'text/html'}
        ])
      })
    })
  })
})
