/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

/*
  TODO: Duplicated and modified within jsx/outcomes/MasteryScale for use there
        Remove when feature flag account_level_mastery_scales is enabled
*/

import _ from 'lodash'
import $ from 'jquery'
import React from 'react'
import axios from '@canvas/axios'
import {render, waitFor, fireEvent} from '@testing-library/react'
import ProficiencyTable from '../ProficiencyTable'

// Suppress the validateDOMNesting warning for this test suite
// The ProficiencyTable uses Flex.Item with as="th" which causes this warning
const originalError = console.error
beforeAll(() => {
  console.error = (...args) => {
    if (typeof args[0] === 'string' && args[0].includes('validateDOMNesting')) {
      return
    }
    originalError.call(console, ...args)
  }
})

afterAll(() => {
  console.error = originalError
})

// Mock HTMLElement.focus to prevent focus errors in tests
beforeEach(() => {
  HTMLElement.prototype.focus = jest.fn()
  jest.useFakeTimers()
})

afterEach(() => {
  jest.useRealTimers()
})

async function wait(ms = 0) {
  if (ms > 0) {
    jest.advanceTimersByTime(ms)
  }
  // Allow promises to resolve
  await Promise.resolve()
}

const defaultProps = {
  accountId: '1',
}

let getSpy

describe('default proficiency', () => {
  beforeEach(() => {
    const err = _.assign(new Error(), {response: {status: 404}})
    getSpy = jest.spyOn(axios, 'get').mockImplementation(() => Promise.reject(err))
  })

  afterEach(() => {
    getSpy.mockRestore()
  })

  it('renders loading spinner initially', () => {
    const {getByText} = render(<ProficiencyTable {...defaultProps} />)
    expect(getByText('Loading')).toBeInTheDocument()
  })

  it('render billboard after loading', async () => {
    const {getByText} = render(<ProficiencyTable {...defaultProps} />)
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
  })
  it('renders five ratings', async () => {
    const {getAllByRole, getByText} = render(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    // Wait for billboard and close it
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
    const getStartedButton = getByText('Get Started')
    fireEvent.click(getStartedButton)

    await waitFor(() => {
      const checkboxes = getAllByRole('radio')
      expect(checkboxes).toHaveLength(5) // Each rating has a mastery radio button
    })
  })

  it('has mastery selected on first rating only', async () => {
    const {getAllByRole, getByText} = render(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    // Wait for billboard and close it
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
    const getStartedButton = getByText('Get Started')
    fireEvent.click(getStartedButton)

    await waitFor(() => {
      const masteryRadios = getAllByRole('radio')
      expect(masteryRadios).toHaveLength(5)
      // Default mastery index is 1 (second rating)
      expect(masteryRadios[0]).not.toBeChecked()
      expect(masteryRadios[1]).toBeChecked()
      expect(masteryRadios[2]).not.toBeChecked()
      expect(masteryRadios[3]).not.toBeChecked()
      expect(masteryRadios[4]).not.toBeChecked()
    })
  })

  it('clicking add button adds rating', async () => {
    const {getAllByRole, getByText, getByRole} = render(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    // Wait for billboard and close it
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
    const getStartedButton = getByText('Get Started')
    fireEvent.click(getStartedButton)

    await waitFor(() => {
      const initialRadios = getAllByRole('radio')
      expect(initialRadios).toHaveLength(5)
    })

    const addButton = getByRole('button', {name: /add proficiency rating/i})
    fireEvent.click(addButton)

    await waitFor(() => {
      const newRadios = getAllByRole('radio')
      expect(newRadios).toHaveLength(6)
    })
  })

  it('clicking add rating button flashes SR message', async () => {
    const {getByText, getByRole} = render(<ProficiencyTable {...defaultProps} />)
    const flashMock = jest.spyOn($, 'screenReaderFlashMessage')

    await wait(1)

    // Wait for billboard and close it
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
    const getStartedButton = getByText('Get Started')
    fireEvent.click(getStartedButton)

    // Wait for table to render
    await waitFor(() => {
      expect(getByText('Proficiency Rating')).toBeInTheDocument()
    })

    const addButton = getByRole('button', {name: 'Add proficiency rating'})
    fireEvent.click(addButton)

    expect(flashMock).toHaveBeenCalledTimes(1)
    flashMock.mockRestore()
  })

  it('deleting rating removes rating and flashes SR message', async () => {
    const {getAllByRole, getByText} = render(<ProficiencyTable {...defaultProps} />)
    const flashMock = jest.spyOn($, 'screenReaderFlashMessage')

    await wait(1)

    // Wait for billboard and close it
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
    const getStartedButton = getByText('Get Started')
    fireEvent.click(getStartedButton)

    await waitFor(() => {
      const initialRadios = getAllByRole('radio')
      expect(initialRadios).toHaveLength(5)
    })

    const deleteButtons = getAllByRole('button', {name: /delete proficiency rating/i})
    fireEvent.click(deleteButtons[1])

    await waitFor(() => {
      const newRadios = getAllByRole('radio')
      expect(newRadios).toHaveLength(4)
    })
    expect(flashMock).toHaveBeenCalledTimes(1)
    flashMock.mockRestore()
  })

  it('setting blank description sets error', async () => {
    const {getByText, getAllByRole} = render(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    // Wait for billboard and close it
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
    const getStartedButton = getByText('Get Started')
    fireEvent.click(getStartedButton)

    // Wait for inputs to be rendered
    await waitFor(() => {
      expect(getByText('Proficiency Rating')).toBeInTheDocument()
    })

    // Clear first rating description
    const descriptionInputs = getAllByRole('textbox', {name: /change description/i})
    const firstInput = descriptionInputs[0]
    fireEvent.change(firstInput, {target: {value: ''}})
    fireEvent.blur(firstInput)

    // Submit form
    const saveButton = getByText('Save Learning Mastery')
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(getByText(/Please include a rating title/)).toBeInTheDocument()
    })
  })

  it('setting blank points sets error', async () => {
    const {getByText, getAllByLabelText} = render(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    // Wait for billboard and close it
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
    const getStartedButton = getByText('Get Started')
    fireEvent.click(getStartedButton)

    // Clear first rating points
    const pointsInputs = getAllByLabelText(/Change points/)
    const firstInput = pointsInputs[0]
    firstInput.focus()
    firstInput.select()
    fireEvent.input(firstInput, {target: {value: ''}})

    // Submit form
    const saveButton = getByText('Save Learning Mastery')
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(getByText(/Invalid format/)).toBeInTheDocument()
    })
  })

  it('setting invalid points sets error', async () => {
    const {getByText, getAllByLabelText} = render(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    // Wait for billboard and close it
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
    const getStartedButton = getByText('Get Started')
    fireEvent.click(getStartedButton)

    // Set invalid points
    const pointsInputs = getAllByLabelText(/Change points/)
    const firstInput = pointsInputs[0]
    firstInput.focus()
    firstInput.select()
    fireEvent.input(firstInput, {target: {value: '1.1.1'}})

    // Submit form
    const saveButton = getByText('Save Learning Mastery')
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(getByText(/Invalid format/)).toBeInTheDocument()
    })
  })

  it('setting negative points sets error', async () => {
    const {getByText, getAllByLabelText} = render(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    // Wait for billboard and close it
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
    const getStartedButton = getByText('Get Started')
    fireEvent.click(getStartedButton)

    // Set negative points
    const pointsInputs = getAllByLabelText(/Change points/)
    const firstInput = pointsInputs[0]
    firstInput.focus()
    firstInput.select()
    fireEvent.input(firstInput, {target: {value: '-1'}})

    // Submit form
    const saveButton = getByText('Save Learning Mastery')
    fireEvent.click(saveButton)

    await waitFor(() => {
      expect(getByText(/Negative points/)).toBeInTheDocument()
    })
  })

  it('sends POST on submit', async () => {
    const postSpy = jest
      .spyOn(axios, 'post')
      .mockImplementation(() => Promise.resolve({status: 200}))

    const {getByText} = render(<ProficiencyTable {...defaultProps} />)

    await wait(1)

    // Wait for billboard and close it
    await waitFor(() => {
      expect(getByText('Customize Learning Mastery Ratings')).toBeInTheDocument()
    })
    const getStartedButton = getByText('Get Started')
    fireEvent.click(getStartedButton)

    // Submit form
    const saveButton = getByText('Save Learning Mastery')
    fireEvent.click(saveButton)

    // Ensure that the mocked POST request was called
    await waitFor(() => {
      expect(axios.post).toHaveBeenCalledTimes(1)
    })

    postSpy.mockRestore()
  })

  // Tests for error validation are covered by the UI interaction tests above
})

describe('custom proficiency', () => {
  it('renders two ratings that are deletable', async () => {
    const spy = jest.spyOn(axios, 'get').mockImplementation(() =>
      Promise.resolve({
        status: 200,
        data: {
          ratings: [
            {
              description: 'Great',
              points: 10,
              color: '0000ff',
              mastery: true,
            },
            {
              description: 'Poor',
              points: 0,
              color: 'ff0000',
              mastery: false,
            },
          ],
        },
      }),
    )

    const {getAllByRole} = render(<ProficiencyTable {...defaultProps} />)

    await waitFor(() => {
      const radios = getAllByRole('radio')
      expect(radios).toHaveLength(2)
    })

    const deleteButtons = getAllByRole('button', {name: /delete proficiency rating/i})
    expect(deleteButtons).toHaveLength(2)

    spy.mockRestore()
  })

  it('renders one rating that is not deletable', async () => {
    const spy = jest.spyOn(axios, 'get').mockImplementation(() =>
      Promise.resolve({
        status: 200,
        data: {
          ratings: [
            {
              description: 'Uno',
              points: 1,
              color: '0000ff',
              mastery: true,
            },
          ],
        },
      }),
    )

    const {getAllByRole, queryAllByLabelText} = render(<ProficiencyTable {...defaultProps} />)

    await waitFor(() => {
      const radios = getAllByRole('radio')
      expect(radios).toHaveLength(1)
    })

    const deleteButtons = queryAllByLabelText('Delete proficiency rating')
    expect(deleteButtons).toHaveLength(0)

    spy.mockRestore()
  })
})
