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

import {render, waitFor, fireEvent} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import EditSectionsModal from '../EditSectionsModal'
import type {ExistingSectionEnrollment} from '../SectionSelector'
import fakeENV from '@canvas/test-utils/fakeENV'

const mockSections: ExistingSectionEnrollment[] = [
  {
    id: '1',
    name: 'Section 1',
    can_be_removed: true,
    role: 'StudentEnrollment',
  },
  {
    id: '2',
    name: 'Section 2',
    can_be_removed: false,
    role: 'StudentEnrollment',
  },
]

const defaultProps = {
  onClose: vi.fn(),
  onUpdate: vi.fn(() => {
    return Promise.resolve()
  }),
  excludeSections: mockSections,
}

describe('EditSectionsModal', () => {
  beforeAll(() => {
    fakeENV.setup({current_context: {id: '123'}})
  })

  beforeEach(() => {
    fetchMock.restore()
    vi.clearAllMocks()
  })

  afterAll(() => {
    fakeENV.teardown()
  })

  afterEach(() => {
    fetchMock.restore()
  })

  it('renders the modal with static elements and default values', () => {
    const {getByText} = render(<EditSectionsModal {...defaultProps} />)

    // static elements
    expect(getByText('Edit Sections')).toBeInTheDocument()
    expect(getByText(/Sections are an additional way to organize users/)).toBeInTheDocument()
    expect(getByText('Cancel')).toBeInTheDocument()
    expect(getByText('Save')).toBeInTheDocument()
    // default sections
    expect(getByText('Section 1 - Student')).toBeInTheDocument()
    expect(getByText('Section 2 - Student')).toBeInTheDocument()
  })

  it('calls onClose when Cancel button is clicked', async () => {
    const {getByText} = render(<EditSectionsModal {...defaultProps} />)

    fireEvent.click(getByText('Cancel'))

    await waitFor(() => {
      expect(defaultProps.onClose).toHaveBeenCalled()
    })
  })

  it('calls onClose when close button in header is clicked', async () => {
    const {getByTestId} = render(<EditSectionsModal {...defaultProps} />)

    fireEvent.click(getByTestId('close-button').querySelector('button')!)

    await waitFor(() => {
      expect(defaultProps.onClose).toHaveBeenCalled()
    })
  })

  it('successfully updates sections when Save is clicked', async () => {
    const {getByText} = render(<EditSectionsModal {...defaultProps} />)

    fireEvent.click(getByText('Save'))

    await waitFor(() => {
      expect(defaultProps.onUpdate).toHaveBeenCalledWith(mockSections)
      expect(defaultProps.onClose).toHaveBeenCalled()
    })
  })

  it('shows error flash message when update fails', async () => {
    const onUpdate = vi.fn().mockRejectedValue(new Error('Update failed'))
    const {getAllByText, getByText} = render(
      <EditSectionsModal {...defaultProps} onUpdate={onUpdate} />,
    )

    fireEvent.click(getByText('Save'))

    await waitFor(() => {
      expect(getAllByText('Failed to update section enrollments').length).toBeGreaterThan(0)
    })
    expect(defaultProps.onClose).toHaveBeenCalled()
  })

  it('allows removing sections that can be removed', async () => {
    const {getByTestId, queryByText} = render(<EditSectionsModal {...defaultProps} />)

    const removeButton = getByTestId('remove-section-1').querySelector('button')!
    fireEvent.click(removeButton)

    await waitFor(() => {
      expect(queryByText('Section 1 - Student')).toBeNull()
    })
  })

  it('allows adding sections via SectionSelector', async () => {
    const fetchSections = encodeURI(
      `/courses/123/sections/user_count?exclude[]=section_1&exclude[]=section_2&search=`,
    )
    const response = {
      sections: [{id: '3', name: 'Section 3', avatar_url: '', user_count: 0}],
    }
    fetchMock.get(fetchSections, response)
    const {getByTestId} = render(<EditSectionsModal {...defaultProps} />)

    const sectionInput = getByTestId('section-input')
    fireEvent.click(sectionInput)
    await waitFor(() => {
      expect(fetchMock.called(fetchSections)).toBe(true)
      expect(getByTestId('section-option-3')).toBeInTheDocument()
    })
    fireEvent.click(getByTestId('section-option-3'))

    await waitFor(() => {
      expect(getByTestId('remove-section-3')).toBeInTheDocument()
    })
  })

  it('does not show remove button for sections that cannot be removed', () => {
    const {queryByTestId} = render(<EditSectionsModal {...defaultProps} />)

    const removeButton = queryByTestId('remove-section-2')
    expect(removeButton).toBeNull()
  })

  it('updates selected sections when Save is clicked after removing a section', async () => {
    const {getByTestId, getByText, queryByText} = render(<EditSectionsModal {...defaultProps} />)

    const removeButton = getByTestId('remove-section-1').querySelector('button')!
    fireEvent.click(removeButton)

    await waitFor(() => {
      expect(queryByText('Section 1 - Student')).toBeNull()
    })

    fireEvent.click(getByText('Save'))

    await waitFor(() => {
      expect(defaultProps.onUpdate).toHaveBeenCalledWith([mockSections[1]])
    })
  })
})
