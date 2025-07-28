/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen, fireEvent, waitFor} from '@testing-library/react'

import AccessibilityIssuesDrawerContent from '..'
import userEvent from '@testing-library/user-event'
import doFetchApiEffect from '@canvas/do-fetch-api-effect'
import {
  multiIssueItem,
  buttonRuleItem,
  checkboxTextInputRuleItem,
  colorPickerRuleItem,
  radioInputGroupRuleItem,
  textInputRuleItem,
} from './__mocks__'

const mockClose = jest.fn()

const baseItem = multiIssueItem

jest.mock('@canvas/do-fetch-api-effect', () => ({
  __esModule: true,
  default: jest.fn(({path}) => {
    if (path.includes('/preview?')) {
      return Promise.resolve({json: {content: '<div>Preview content</div>'}})
    }
    if (path.includes('/preview')) {
      return Promise.resolve({json: {content: '<div>Updated content</div>'}})
    }
    return Promise.resolve({})
  }),
}))

jest.mock('use-debounce', () => ({
  __esModule: true,
  useDebouncedCallback: jest.fn((callback, _delay) => callback),
}))

describe('AccessibilityIssuesDrawerContent', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('renders the title and issue counter', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)
    expect(await screen.findByText('Multi Issue Test Page')).toBeInTheDocument()
    expect(screen.getByText(/Issue 1\/2:/)).toBeInTheDocument()
  })

  it('disables "Back" on first issue and enables "Next"', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)
    const back = screen.getByTestId('back-button')
    const next = screen.getByTestId('next-button')

    expect(back).toBeDisabled()
    expect(next).toBeEnabled()
  })

  it('disables "Next" on last issue', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

    const next = screen.getByTestId('next-button')
    fireEvent.click(next)

    await waitFor(() => {
      expect(screen.getByText(/Issue 2\/2:/)).toBeInTheDocument()
      expect(next).toBeDisabled()
    })
  })

  it('removes issue on save and next', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

    const saveAndNext = screen.getByTestId('save-and-next-button')
    expect(saveAndNext).toBeDisabled()

    const apply = screen.getByTestId('apply-button')
    fireEvent.click(apply)

    await waitFor(() => {
      expect(saveAndNext).toBeEnabled()
      fireEvent.click(saveAndNext)
    })

    await waitFor(() => {
      expect(screen.getByText(/Issue 1\/1:/)).toBeInTheDocument()
    })
  })

  it('renders Open Page and Edit Page links', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

    expect(await screen.findByText('Open Page')).toHaveAttribute(
      'href',
      'http://test.com/multi-issue-page',
    )
    expect(screen.getByText('Edit Page')).toHaveAttribute(
      'href',
      'http://test.com/multi-issue-page/edit',
    )
  })

  it('calls onClose when close button is clicked', async () => {
    render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

    const closeButton = screen
      .getByTestId('close-button')
      .querySelector('button') as HTMLButtonElement
    fireEvent.click(closeButton)

    expect(mockClose).toHaveBeenCalledTimes(1)
  })

  describe('Save and Next button', () => {
    describe('is enabled', () => {
      it('when the issue is remediated', async () => {
        render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeDisabled()

        const apply = screen.getByTestId('apply-button')
        await userEvent.click(apply)
        expect(saveAndNext).toBeEnabled()
      })

      it('when the form type is CheckboxTextInput (apply button hidden)', () => {
        render(
          <AccessibilityIssuesDrawerContent item={checkboxTextInputRuleItem} onClose={mockClose} />,
        )

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeEnabled()
      })
    })

    describe('is disabled', () => {
      it('when the issue is not remediated', () => {
        render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeDisabled()
      })

      it('when the form is locked during apply operation', () => {
        render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

        const apply = screen.getByTestId('apply-button')

        // Use fireEvent to simulate the click event without waiting for load state
        fireEvent.click(apply)

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeDisabled()
      })

      it('when the form is locked during undo operation', async () => {
        render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

        const apply = screen.getByTestId('apply-button')
        await userEvent.click(apply)

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeEnabled()

        const undo = screen.getByTestId('undo-button')
        await userEvent.click(undo)

        expect(saveAndNext).toBeDisabled()
      })

      it('when there is a form error', async () => {
        render(<AccessibilityIssuesDrawerContent item={baseItem} onClose={mockClose} />)

        // Mock the doFetchApiEffect to return an error
        ;(doFetchApiEffect as jest.Mock).mockRejectedValueOnce(new Error('Test error'))

        const apply = screen.getByTestId('apply-button')
        await userEvent.click(apply)

        const saveAndNext = screen.getByTestId('save-and-next-button')
        expect(saveAndNext).toBeDisabled()
      })
    })
  })

  describe('show errors on apply', () => {
    it('for FormType.Button', async () => {
      render(<AccessibilityIssuesDrawerContent item={buttonRuleItem} onClose={mockClose} />)

      // Mock the doFetchApiEffect to return an error
      ;(doFetchApiEffect as jest.Mock).mockRejectedValueOnce(new Error('Test error'))

      const apply = screen.getByTestId('apply-button')
      await userEvent.click(apply)

      expect(screen.getAllByText('Test error')[0]).toBeInTheDocument()
    })

    it('for FormType.CheckboxTextInput', async () => {
      render(
        <AccessibilityIssuesDrawerContent item={checkboxTextInputRuleItem} onClose={mockClose} />,
      )

      // Mock the doFetchApiEffect to return an error
      ;(doFetchApiEffect as jest.Mock).mockRejectedValueOnce(new Error('Test error'))

      const textarea = screen.getByTestId('checkbox-text-input-form')
      await userEvent.type(textarea, '1')

      await waitFor(() => {
        expect(screen.getAllByText('Test error')[0]).toBeInTheDocument()
      })
    })

    it('for FormType.ColorPicker', async () => {
      render(<AccessibilityIssuesDrawerContent item={colorPickerRuleItem} onClose={mockClose} />)

      // Mock the doFetchApiEffect to return an error
      ;(doFetchApiEffect as jest.Mock).mockRejectedValueOnce(new Error('Test error'))

      const apply = screen.getByTestId('apply-button')
      await userEvent.click(apply)

      expect(screen.getAllByText('Test error')[0]).toBeInTheDocument()
    })

    it('for FormType.RadioInputGroup', async () => {
      render(
        <AccessibilityIssuesDrawerContent item={radioInputGroupRuleItem} onClose={mockClose} />,
      )

      // Mock the doFetchApiEffect to return an error
      ;(doFetchApiEffect as jest.Mock).mockRejectedValueOnce(new Error('Test error'))

      const apply = screen.getByTestId('apply-button')
      await userEvent.click(apply)

      expect(screen.getAllByText('Test error')[0]).toBeInTheDocument()
    })

    it('for FormType.TextInput', async () => {
      render(<AccessibilityIssuesDrawerContent item={textInputRuleItem} onClose={mockClose} />)

      // Mock the doFetchApiEffect to return an error
      ;(doFetchApiEffect as jest.Mock).mockRejectedValueOnce(new Error('Test error'))

      const apply = screen.getByTestId('apply-button')
      await userEvent.click(apply)

      expect(screen.getAllByText('Test error')[0]).toBeInTheDocument()
    })
  })
})
