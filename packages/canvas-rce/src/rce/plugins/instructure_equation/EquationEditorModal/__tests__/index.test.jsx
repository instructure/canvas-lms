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
import {act, fireEvent, render, screen, waitFor} from '@testing-library/react'
import EquationEditorModal from '../index'
import {MathJaxDirective, Mathml} from '../../../../../enhance-user-content/mathml'
import advancedPreference from '../advancedPreference'
import {MathfieldElement} from 'mathlive'
import RCEGlobals from '../../../../RCEGlobals'

jest.useFakeTimers()

const r = String.raw

const defaultProps = () => {
  return {
    editor: {},
    onEquationSubmit: () => {},
    onModalDismiss: () => {},
    onModalClose: () => {},
    mountNode: null,
    originalLatex: {},
    openAdvanced: false,
  }
}

const renderModal = (overrideProps = {}) => {
  const props = defaultProps()
  return render(<EquationEditorModal {...props} {...overrideProps} />)
}

const basicEditor = () => document.body.querySelector('math-field')

const advancedEditor = () => document.body.querySelector('textarea')

const advancedPreview = () => screen.getByTestId('mathml-preview-element')

const toggle = () => screen.getByTestId('advanced-toggle')

const tooltip = () => screen.queryByText('This equation cannot be rendered in Basic View.')

const toggleMode = () => fireEvent.click(toggle())

const editInAdvancedMode = text => {
  fireEvent.change(advancedEditor(), {target: {value: text}})
}

jest.mock('../advancedPreference', () => {
  return {
    isSet: jest.fn(),
    set: jest.fn(),
    remove: jest.fn(),
  }
})

describe('EquationEditorModal', () => {
  let mockFn, mathml

  afterAll(() => {
    jest.resetAllMocks()
  })

  beforeEach(() => {
    mockFn = jest.fn()
    mathml = new Mathml()
    MathfieldElement.prototype.setOptions = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
    delete MathfieldElement.prototype.setOptions
  })

  it('disables all the basic editor macros', () => {
    renderModal()
    expect(MathfieldElement.prototype.setOptions).toHaveBeenCalledWith({macros: {}})
  })

  describe('on submit', () => {
    it('calls onEquationSubmit with value', () => {
      renderModal({onEquationSubmit: mockFn})
      basicEditor().setValue('hello')
      fireEvent.click(screen.getByText('Done'))
      expect(mockFn).toHaveBeenCalledWith('hello')
    })

    it('does not call onEquationSubmit with empty value', () => {
      renderModal({onEquationSubmit: mockFn})
      basicEditor().setValue('')
      fireEvent.click(screen.getByText('Done'))
      expect(mockFn).not.toHaveBeenCalled()
    })

    it('calls onEquationSubmit on advanced input with value', () => {
      renderModal({onEquationSubmit: mockFn})
      toggleMode()
      editInAdvancedMode('hello')
      fireEvent.click(screen.getByText('Done'))
      expect(mockFn).toHaveBeenCalledWith('hello')
    })

    it('does not not call onEquationSubmit with empty value on advanced input', () => {
      renderModal({onEquationSubmit: mockFn})
      toggleMode()
      editInAdvancedMode('')
      fireEvent.click(screen.getByText('Done'))
      expect(mockFn).not.toHaveBeenCalled()
    })
  })

  it('preserves content from initial to advanced field', () => {
    renderModal()
    basicEditor().setValue('hello')
    toggleMode()
    const newValue = advancedEditor().value
    expect(newValue).toEqual('hello')
  })

  it('preserves content from advanced to initial field', () => {
    renderModal()
    toggleMode()
    editInAdvancedMode('hello')
    toggleMode()
    const newValue = basicEditor().getValue()
    expect(newValue).toEqual('hello')
  })

  describe('opening mode', () => {
    it('is basic by default', () => {
      renderModal()
      expect(toggle()).not.toBeChecked()
    })

    it('is advanced if openAdvanced is true', () => {
      renderModal({openAdvanced: true})
      expect(toggle()).toBeChecked()
    })

    it('is advanced if originalLatex.advancedOnly is true', () => {
      renderModal({originalLatex: {advancedOnly: true}})
      expect(toggle()).toBeChecked()
    })
  })

  describe('original display value', () => {
    it('is nothing by default', () => {
      renderModal()
      expect(basicEditor().getValue()).toEqual('')
    })

    it('matches original latex in basic mode', () => {
      renderModal({originalLatex: {latex: r`\sqrt{x}`}})
      expect(basicEditor().getValue()).toEqual(r`\sqrt{x}`)
    })

    it('matches original latex in advanced mode', () => {
      renderModal({originalLatex: {latex: r`\sqrt{x}`, advancedOnly: true}})
      expect(advancedEditor().value).toEqual(r`\sqrt{x}`)
    })
  })

  describe('advanced preview', () => {
    it('is marked as MathJax should process', () => {
      renderModal()
      const shouldProcess = mathml.shouldProcess(advancedPreview())
      expect(shouldProcess).toBe(true)
    })

    it('does not have process directive if explicit_latex_typsetting is off', () => {
      jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({explicit_latex_typesetting: false})
      renderModal({openAdvanced: true})
      expect(advancedPreview()).not.toHaveClass(MathJaxDirective.Process)
    })

    it('contains the process directive if explicit_latex_typesetting is on', () => {
      jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({explicit_latex_typesetting: true})
      renderModal({openAdvanced: true})
      expect(advancedPreview()).toHaveClass(MathJaxDirective.Process)
    })

    describe('correctly renders when', () => {
      let actualDebounceRate
      const testDebounceRate = 100

      beforeAll(() => {
        jest.spyOn(RCEGlobals, 'getFeatures').mockReturnValue({explicit_latex_typesetting: false})
        jest.spyOn(Mathml.prototype, 'processNewMathInElem')
        actualDebounceRate = EquationEditorModal.debounceRate
        EquationEditorModal.debounceRate = testDebounceRate
      })

      afterAll(() => {
        EquationEditorModal.debounceRate = actualDebounceRate
      })

      it('toggling from basic to advanced mode', async () => {
        renderModal({originalLatex: {latex: r`\sqrt{x}`}})
        toggleMode()
        await waitFor(() => {
          expect(mathml.processNewMathInElem.mock.calls[0][0]).toMatchInlineSnapshot(`
            <span
              data-testid="mathml-preview-element"
            >
              \\(\\sqrt{x}\\)
            </span>
          `)
        })
      })

      it('updating formula in advanced mode', async () => {
        renderModal({openAdvanced: true})
        editInAdvancedMode('hello')
        await act(async () => jest.runAllTimers())
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

      it('deleting formula in advanced editor', async () => {
        renderModal({originalLatex: {latex: r`\LaTeX`, advancedOnly: true}})
        editInAdvancedMode('')
        await waitFor(() => {
          expect(advancedPreview().innerHTML).toEqual('')
        })
      })

      it('deleting formula in basic editor', async () => {
        renderModal({openAdvanced: true})
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
  })

  describe('should disable basic mode when', () => {
    it('user enters an advanced command in basic mode', async () => {
      // This test simulates a user pasting in a latex string
      // that matches the advanced only criteria

      renderModal()

      // Need to trigger the event listener on the <math-field>.
      // Testing library built in features don't allow us to do
      // this on their own.
      const event = new Event('input')
      Object.defineProperty(event, 'target', {
        get: () => {
          return {value: r`\displaystyle x`}
        },
      })

      basicEditor().dispatchEvent(event)
      await waitFor(() => {
        expect(toggle()).toBeChecked()
        expect(toggle()).toBeDisabled()
      })
    })

    it('user enters an advanced only command in the advanced editor', async () => {
      renderModal({openAdvanced: true})
      editInAdvancedMode(r`\displaystyle x`)
      await waitFor(() => {
        expect(toggle()).toBeDisabled()
      })
    })
  })

  describe('toggle toolip', () => {
    it('exists when basic mode is disabled', async () => {
      renderModal({openAdvanced: true})
      editInAdvancedMode(r`\displaystyle x`)
      await waitFor(() => {
        expect(tooltip()).toBeInTheDocument()
        expect(tooltip()).not.toBeVisible()
      })
    })

    it('does not exist when basic mode is not disabled', async () => {
      renderModal()
      basicEditor().setValue(r`\sqrt{x}`)
      await waitFor(() => {
        expect(tooltip()).not.toBeInTheDocument()
      })
    })

    it('renders on hover', async () => {
      renderModal({openAdvanced: true})
      editInAdvancedMode(r`\displaystyle x`)
      fireEvent.focus(toggle())
      await waitFor(() => {
        expect(tooltip()).toBeInTheDocument()
        expect(tooltip()).toBeVisible()
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

  describe('advanced mode flag', () => {
    it('is cleared when the user toggles from advanced to basic mode', () => {
      advancedPreference.isSet.mockReturnValueOnce(true)
      renderModal()
      toggleMode()
      expect(advancedPreference.remove).toHaveBeenCalled()
    })

    it('is set when the user toggles from basic to advanced mode', () => {
      advancedPreference.isSet.mockReturnValueOnce(false)
      renderModal()
      toggleMode()
      expect(advancedPreference.set).toHaveBeenCalled()
    })
  })
})
