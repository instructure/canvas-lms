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

import {selectionIsLatex, cleanLatex, findLatex, parseLatex} from '../parseLatex'

const r = String.raw

describe('selectionIsLatex', () => {
  it('returns true for inline style delimited latex', () => {
    const testString = r`\(valid latex\)`
    expect(selectionIsLatex(testString)).toBe(true)
  })

  it('returns true for display style delimited latex', () => {
    const testString = '$$valid latex$$'
    expect(selectionIsLatex(testString)).toBe(true)
  })

  it('returns false for other incorrectly formatted strings', () => {
    ;[r`\(mismatched latex$$`, '$almostmadelatex$', 'randomtext'].forEach(testString => {
      expect(selectionIsLatex(testString)).toBe(false)
    })
  })
})

describe('cleanLatex', () => {
  it('removes first two and last two characters from input', () => {
    const testString = r`\(\LaTeX\)`
    expect(cleanLatex(testString)).toEqual(r`\LaTeX`)
  })

  it('removes extraneous &npsb;', () => {
    const testString = r`$$&nbsp;&nbsp;\LaTeX&nbsp;&nbsp;$$`
    expect(cleanLatex(testString)).toEqual(r`\LaTeX`)
  })
})

describe('findLatex', () => {
  it('returns an empty object if there are no latex matches on the input string', () => {
    ;['', 'abc', '123'].forEach(nonLatexString => {
      expect(findLatex(nonLatexString, 0)).toEqual({})
    })
  })

  it('returns an empty object if the cursor is outside of valid latex', () => {
    const latexString = r`\(LaTeX\)`
    expect(findLatex(latexString, 100)).toEqual({})
  })

  it('finds latex and range boundaries when valid latex is present in the input string', () => {
    const latexString = r`$$\LaTeX$$`
    expect(findLatex(latexString, 3)).toEqual({
      latex: r`\LaTeX`,
      leftIndex: 0,
      rightIndex: 10,
    })
  })

  it('finds the latex surrounding the cursor if there are multiple valid matches', () => {
    const latexString = r`\(test\)\(this\)\(out\)`
    expect(findLatex(latexString, 12)).toEqual({
      latex: 'this',
      leftIndex: 8,
      rightIndex: 16,
    })
  })
})

describe('parseLatex', () => {
  const editor: any = {
    selection: {
      getContent: jest.fn(),
      getNode: jest.fn(),
      getRng: jest.fn(() => ({
        startContainer: {
          wholeText: '',
        },
      })),
    },
  }

  describe('when the selection is a latex string', () => {
    it('determines the latex and advanced only correctly', () => {
      editor.selection.getContent.mockImplementationOnce(() => r`\(\LaTeX\)`)
      expect(parseLatex(editor)).toEqual({
        latex: r`\LaTeX`,
        advancedOnly: true,
      })
    })
  })

  describe('when the selection is an image', () => {
    it('determines the latex and advanced only correctly', () => {
      editor.selection.getNode.mockImplementationOnce(() => ({
        tagName: 'IMG',
        classList: {
          contains: (str: string) => str === 'equation_image',
        },
        src: 'http://canvas.docker/equation_images/%255Csqrt%257Bx%257D',
      }))
      expect(parseLatex(editor)).toEqual({
        latex: r`\sqrt{x}`,
        advancedOnly: false,
      })
    })

    it('returns an empty object if the parsing fails', () => {
      editor.selection.getNode.mockImplementationOnce(() => ({
        tagName: 'IMG',
        classList: {
          contains: (str: string) => str === 'equation_image',
        },
      }))
      expect(parseLatex(editor)).toEqual({})
    })
  })

  describe('when the selection is a range', () => {
    it('returns the parsed latex and relevant attributes for valid latex', () => {
      editor.selection.getRng.mockImplementationOnce(() => ({
        startContainer: {
          wholeText: 'x^2',
          nodeValue: r`\(x^2\)`,
        },
        startOffset: 3,
      }))
      expect(parseLatex(editor)).toEqual({
        latex: 'x^2',
        advancedOnly: false,
        leftIndex: 0,
        rightIndex: 7,
        startContainer: {
          wholeText: 'x^2',
          nodeValue: r`\(x^2\)`,
        },
      })
    })

    it('returns an empty object when latex is not found', () => {
      editor.selection.getRng.mockImplementationOnce(() => ({
        startContainer: {
          wholeText: 'notlatex',
          nodeValue: 'notlatex',
        },
        startOffset: 0,
      }))
      expect(parseLatex(editor)).toEqual({})
    })
  })

  describe('when the selection is not a latex string, image, or range', () => {
    it('returns an empty object', () => {
      expect(parseLatex(editor)).toEqual({})
    })
  })
})
