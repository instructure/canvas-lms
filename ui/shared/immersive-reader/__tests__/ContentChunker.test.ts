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
  const options = {}
  const chunker = new ContentChunker(options)

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
          content: '<div>\n        Some simple content\n        </div>',
          mimeType: 'text/html',
        },
        {
          content: '<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>',
          mimeType: 'application/mathml+xml',
        },
        {
          content: 'Some post math content\n      \n    ',
          mimeType: 'text/html',
        },
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
            mimeType: 'text/html',
          },
        ])
      })
    })

    describe('with multiple adjacent math chunks', () => {
      beforeEach(() => {
        content = `
          <div>
            Pre-math
            <p>
              <span class="math_equation_latex fade-in-equation" style="null">
                  <span class="MathJax_Preview" style="color: inherit;"></span>
                  <span class="MathJax_SVG" id="MathJax-Element-2-Frame" tabindex="0" data-mathml="<math xmlns=&quot;http://www.w3.org/1998/Math/MathML&quot;><mi>A</mi><mo>=</mo><mi>&amp;#x03C0;</mi><msup><mi>r</mi><mn>2</mn></msup></math>" role="presentation">
                     <svg xmlns:xlink="http://www.w3.org/1999/xlink" width="8.276ex" height="2.355ex" viewBox="0 -905.6 3563.5 1013.9" role="img" focusable="false" style="vertical-align: -0.252ex;" aria-hidden="true">
                        <g stroke="currentColor" fill="currentColor" stroke-width="0" transform="matrix(1 0 0 -1 0 0)">
                           <g transform="translate(2658,0)">
                              <use xlink:href="#MJMATHI-72" x="0" y="0"></use>
                           </g>
                        </g>
                     </svg>
                     <span class="MJX_Assistive_MathML" role="presentation">
                        <math xmlns="http://www.w3.org/1998/Math/MathML">
                           <mi>A</mi>
                           <mo>=</mo>
                           <mi>π</mi>
                           <msup>
                              <mi>r</mi>
                              <mn>2</mn>
                           </msup>
                        </math>
                     </span>
                  </span>
                  <script type="math/tex" id="MathJax-Element-2">A=\pi r^2</script>
              </span>
            </p>
            <p>
              <span class="math_equation_latex fade-in-equation" style="null">
                  <span class="MathJax_Preview" style="color: inherit;"></span>
                  <span class="MathJax_SVG" id="MathJax-Element-2-Frame" tabindex="0" data-mathml="<math xmlns=&quot;http://www.w3.org/1998/Math/MathML&quot;><mi>A</mi><mo>=</mo><mi>&amp;#x03C0;</mi><msup><mi>r</mi><mn>2</mn></msup></math>" role="presentation">
                     <svg xmlns:xlink="http://www.w3.org/1999/xlink" width="8.276ex" height="2.355ex" viewBox="0 -905.6 3563.5 1013.9" role="img" focusable="false" style="vertical-align: -0.252ex;" aria-hidden="true">
                        <g stroke="currentColor" fill="currentColor" stroke-width="0" transform="matrix(1 0 0 -1 0 0)">
                           <g transform="translate(2658,0)">
                              <use xlink:href="#MJMATHI-72" x="0" y="0"></use>
                           </g>
                        </g>
                     </svg>
                     <span class="MJX_Assistive_MathML" role="presentation">
                        <math xmlns="http://www.w3.org/1998/Math/MathML">
                           <mi>A</mi>
                           <mo>=</mo>
                           <mi>π</mi>
                           <msup>
                              <mi>a</mi>
                              <mn>3</mn>
                           </msup>
                        </math>
                     </span>
                  </span>
                  <script type="math/tex" id="MathJax-Element-2">A=\pi r^2</script>
              </span>
            </p>
            Post-math
          </div>
        `
      })

      it('returns a chunk for each piece of math with empty math paragraphs removed', () => {
        expect(subject()).toMatchObject([
          {
            content: '<div>\n            Pre-math\n            </div>',
            mimeType: 'text/html',
          },
          {
            content:
              '<math xmlns="http://www.w3.org/1998/Math/MathML"><mi>A</mi><mo>=</mo><mi>&#x03C0;</mi><msup><mi>r</mi><mn>2</mn></msup></math>',
            mimeType: 'application/mathml+xml',
          },
          {
            content: '<p>\n              \n                  \n                  </p>',
            mimeType: 'text/html',
          },
          {
            content:
              '<math xmlns="http://www.w3.org/1998/Math/MathML"><mi>A</mi><mo>=</mo><mi>&#x03C0;</mi><msup><mi>r</mi><mn>2</mn></msup></math>',
            mimeType: 'application/mathml+xml',
          },
          {content: 'Post-math\n          \n        ', mimeType: 'text/html'},
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
            content: '<div>\n            Pre-math\n            </div>',
            mimeType: 'text/html',
          },
          {
            content: '<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>',
            mimeType: 'application/mathml+xml',
          },
          {content: 'Between Math\n            ', mimeType: 'text/html'},
          {
            content: '<mrow><apply><minus/><ci>b</ci><ci>c</ci></apply></mrow>',
            mimeType: 'application/mathml+xml',
          },
          {content: 'Post-math\n          \n        ', mimeType: 'text/html'},
        ])
      })
    })
  })
})
