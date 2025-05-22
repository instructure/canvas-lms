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
  let chunker: ContentChunker
  let content: string

  beforeEach(() => {
    chunker = new ContentChunker({})
  })

  describe('chunk()', () => {
    beforeEach(() => {
      content = `
        <div>
          <img src="something"
            class="MathJax_SVG"
            data-mathml="<mrow><apply><minus/><ci>a</ci><ci>b</ci></apply></mrow>"
          />
        </div>
      `
    })

    const subject = () => chunker.chunk(content)

    it('creates chunks of HTML and MathML', () => {
      const result = subject()
      expect(result.length).toBeGreaterThan(0)

      // Verify HTML chunk
      const htmlChunks = result.filter(chunk => chunk.mimeType === 'text/html')
      expect(htmlChunks.length).toBeGreaterThan(0)

      // Verify MathML chunk
      const mathChunks = result.filter(chunk => chunk.mimeType === 'application/mathml+xml')
      expect(mathChunks).toHaveLength(1)

      // Verify MathML content
      const mathChunk = mathChunks[0]
      expect(mathChunk.content).toContain('<mrow>')
      expect(mathChunk.content).toContain('<apply>')
      expect(mathChunk.content).toContain('<ci>a</ci>')
      expect(mathChunk.content).toContain('<ci>b</ci>')
    })

    describe('with content set to ""', () => {
      beforeEach(() => {
        content = ''
      })

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
        const result = subject()
        expect(result.length).toBeGreaterThan(0)

        // Verify we have at least two MathML chunks
        const mathChunks = result.filter(chunk => chunk.mimeType === 'application/mathml+xml')
        expect(mathChunks.length).toBeGreaterThan(1)

        // Verify the first MathML chunk contains the expected content
        expect(mathChunks[0].content).toContain('<math')
        expect(mathChunks[0].content).toContain('<mi>A</mi>')

        // Verify the HTML chunks
        const htmlChunks = result.filter(chunk => chunk.mimeType === 'text/html')
        expect(htmlChunks.length).toBeGreaterThan(0)

        // Verify the first HTML chunk contains Pre-math
        expect(htmlChunks[0].content).toContain('Pre-math')

        // Verify the last HTML chunk contains Post-math
        const lastHtmlChunk = htmlChunks[htmlChunks.length - 1]
        expect(lastHtmlChunk.content).toContain('Post-math')
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
        const result = subject()
        expect(result.length).toBeGreaterThan(0)

        // Verify we have at least two MathML chunks
        const mathChunks = result.filter(chunk => chunk.mimeType === 'application/mathml+xml')
        expect(mathChunks).toHaveLength(2)

        // Verify the first MathML chunk contains a and b
        expect(mathChunks[0].content).toContain('<ci>a</ci>')
        expect(mathChunks[0].content).toContain('<ci>b</ci>')

        // Verify the second MathML chunk contains b and c
        expect(mathChunks[1].content).toContain('<ci>b</ci>')
        expect(mathChunks[1].content).toContain('<ci>c</ci>')

        // Verify the HTML chunks
        const htmlChunks = result.filter(chunk => chunk.mimeType === 'text/html')
        expect(htmlChunks.length).toBeGreaterThan(0)

        // Verify the content of HTML chunks
        expect(htmlChunks.some(chunk => chunk.content.includes('Pre-math'))).toBe(true)
        expect(htmlChunks.some(chunk => chunk.content.includes('Between Math'))).toBe(true)
        expect(htmlChunks.some(chunk => chunk.content.includes('Post-math'))).toBe(true)
      })
    })
  })
})
