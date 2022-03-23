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

import React from 'react'
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import EquationEditorModal from '../index'
import mathml from '../mathml'

const defaultProps = () => {
  return {
    editor: {},
    label: '',
    onEquationSubmit: () => {},
    onModalDismiss: () => {},
    onModalClose: () => {},
    title: '',
    mountNode: null
  }
}

const renderModal = (overrideProps = {}) => {
  const props = defaultProps()
  return render(<EquationEditorModal {...props} {...overrideProps} />)
}

const basicEditor = () => document.body.querySelector('math-field')

const advancedPreview = () => screen.getByTestId('mathml-preview-element')

const toggleMode = () => {
  fireEvent.click(screen.getByLabelText('Directly Edit LaTeX'))
}

const editInAdvancedMode = text => {
  const textarea = document.body.querySelector('textarea')
  fireEvent.change(textarea, {target: {value: text}})
}

jest.mock('../mathml', () => ({
  processNewMathInElem: jest.fn()
}))

describe('EquationEditorModal', () => {
  let editor, mockFn

  beforeAll(() => {
    HTMLElement.prototype.getValue = jest.fn().mockImplementation(function () {
      if (this.tagName === 'MATH-FIELD') {
        return this.innerHTML
      }
      return null
    })

    HTMLElement.prototype.setValue = jest.fn().mockImplementation(function (value) {
      if (this.tagName === 'MATH-FIELD') {
        this.innerHTML = value
      }
    })
  })

  beforeEach(() => {
    mockFn = jest.fn()
    editor = {
      insertContent: mockFn,
      selection: {
        getContent: () => '\\(latexcontent\\)',
        getNode: () => ({
          tagName: 'IMG',
          classList: {
            contains: str => str === 'equation_image'
          },
          src: 'http://canvas.docker/equation_images/%255Csqrt%257Bx%257D'
        }),
        getRng: () => ({
          startContainer: {
            wholeText: 'text',
            nodeValue: '\\\\\\((text)\\\\\\)'
          },
          startOffset: 0
        })
      }
    }
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('loadExistingFormula()', () => {
    it('selected content is latex', async () => {
      renderModal({editor})
      await waitFor(() => {
        const value = basicEditor().getValue()
        expect(value).toEqual('latexcontent')
      })
    })

    it('selected content is an image', async () => {
      editor.selection.getContent = () => 'non-latex-content'
      renderModal({editor})
      await waitFor(() => {
        const value = basicEditor().getValue()
        expect(value).toEqual('\\sqrt{x}')
      })
    })

    describe('selected content is range', () => {
      beforeEach(() => {
        editor.selection.getContent = () => 'non-latex-content'
        editor.selection.getNode = () => ({
          tagName: 'X',
          classList: {
            contains: () => false
          },
          src: 'http://canvas.docker/equation_images/%255Csqrt%257Bx%257D'
        })
        document.createRange = () => ({
          setStart: () => {},
          setEnd: () => {}
        })
      })

      it('with empty text', async () => {
        editor.selection.getRng = () => ({
          startContainer: {
            wholeText: '',
            nodeValue: null
          },
          startOffset: 0
        })
        renderModal({editor})
        await waitFor(() => {
          const value = basicEditor().getValue()
          expect(value).toEqual('')
        })
      })

      it('with a non formula text', async () => {
        editor.selection.getRng = () => ({
          startContainer: {
            wholeText: 'text',
            nodeValue: 'text'
          },
          startOffset: 0
        })
        renderModal({editor})
        await waitFor(() => {
          const value = basicEditor().getValue()
          expect(value).toEqual('')
        })
      })

      it('formula text', async () => {
        editor.selection.getRng = () => ({
          startContainer: {
            wholeText: 'hello',
            nodeValue: '\\\\\\((text)\\\\\\)'
          },
          startOffset: 5
        })
        editor.selection.setRng = jest.fn()
        renderModal({editor})
        await waitFor(() => {
          const value = basicEditor().getValue()
          expect(editor.selection.setRng).toHaveBeenCalled()
          expect(value).toEqual('(text)\\\\')
        })
      })
    })
  })

  it('uses editor on modal submit', () => {
    renderModal({editor, onEquationSubmit: mockFn})
    basicEditor().setValue('hello')
    fireEvent.click(screen.getByText('Done'))
    expect(mockFn).toHaveBeenCalledWith('hello')
  })

  it('not uses editor on modal submit with empty value', () => {
    renderModal({editor})
    basicEditor().setValue('')
    fireEvent.click(screen.getByText('Done'))
    expect(mockFn).not.toHaveBeenCalled()
  })

  it('uses editor on modal submit on advanced input', () => {
    renderModal({editor, onEquationSubmit: mockFn})
    toggleMode()
    editInAdvancedMode('hello')
    fireEvent.click(screen.getByText('Done'))
    expect(mockFn).toHaveBeenCalledWith('hello')
  })

  it('not uses editor on modal submit with empty value on advanced input', () => {
    renderModal({editor})
    toggleMode()
    editInAdvancedMode('')
    fireEvent.click(screen.getByText('Done'))
    expect(mockFn).not.toHaveBeenCalled()
  })

  it('preserves content from initial to advanced field', () => {
    renderModal({editor})
    basicEditor().setValue('hello')
    toggleMode()
    const textarea = document.body.querySelector('textarea')
    const newValue = textarea.value
    expect(newValue).toEqual('hello')
  })

  it('preserves content from advanced to initial field', () => {
    renderModal({editor})
    toggleMode()
    editInAdvancedMode('hello')
    toggleMode()
    const newValue = basicEditor().getValue()
    expect(newValue).toEqual('hello')
  })

  describe('correctly renders advanced preview when', () => {
    let actualDebounceRate
    const testDebounceRate = 100

    beforeAll(() => {
      actualDebounceRate = EquationEditorModal.debounceRate
      EquationEditorModal.debounceRate = testDebounceRate
    })

    afterAll(() => {
      EquationEditorModal.debounceRate = actualDebounceRate
    })

    it('recovering last formula', async () => {
      renderModal({editor})
      await waitFor(() => {
        const value = basicEditor().getValue()
        expect(value).toEqual('latexcontent')
      })
      toggleMode()
      await waitFor(() => {
        expect(mathml.processNewMathInElem.mock.calls[0][0]).toMatchInlineSnapshot(`
          <span
            data-testid="mathml-preview-element"
          >
            \\(latexcontent\\)
          </span>
        `)
      })
    })

    it('updating formula', async () => {
      renderModal({editor})
      toggleMode()
      editInAdvancedMode('hello')
      await waitFor(() => {
        expect(mathml.processNewMathInElem.mock.calls[0][0]).toMatchInlineSnapshot(`
          <span
            data-testid="mathml-preview-element"
          >
            \\(hello\\)
          </span>
        `)
      })
    })

    it('deleting formula in advanced edtior', async () => {
      renderModal({editor})
      await waitFor(() => {
        const value = basicEditor().getValue()
        expect(value).toEqual('latexcontent')
      })
      toggleMode()
      editInAdvancedMode('')
      await waitFor(() => {
        expect(advancedPreview().innerHTML).toEqual('')
      })
    })

    it('deleting formula in basic editor', async () => {
      renderModal({editor})
      toggleMode()
      editInAdvancedMode('updated in advanced mode')
      toggleMode()
      await waitFor(() => {
        const value = basicEditor().getValue()
        expect(value).toEqual('updated in advanced mode')
      })
      basicEditor().setValue('')
      toggleMode()
      await waitFor(() => {
        expect(advancedPreview().innerHTML).toEqual('')
      })
    })
  })

  it('calls prop onModalDismiss on modal dismiss', () => {
    renderModal({onModalDismiss: mockFn})
    fireEvent.click(screen.getByText('Cancel'))
    expect(mockFn).toHaveBeenCalled()
  })

  it('calls prop onModalDismiss on close button click', () => {
    renderModal({onModalDismiss: mockFn})
    fireEvent.click(screen.getByText('Close'))
    expect(mockFn).toHaveBeenCalled()
  })
})
