/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import { render, fireEvent } from '@testing-library/react'
import FormContent from '../FormContent'
import { EVERYONE } from '../PostTypes'

describe('PostAssignmentGradesTray FormContent', () => {
  const defaultProps = {
    assignment: {
      anonymousGrading: false,
      gradesPublished: true,
    },
    dismiss: jest.fn(),
    postBySections: true,
    postBySectionsChanged: jest.fn(),
    postingGrades: false,
    postType: EVERYONE,
    postTypeChanged: jest.fn(),
    onPostClick: jest.fn(),
    sections: [
      { id: '2001', name: 'Freshmen' },
      { id: '2002', name: 'Sophomores' },
    ],
    sectionSelectionChanged: jest.fn(),
    selectedSectionIds: [],
    unpostedCount: 0,
  }

  function renderComponent(props = {}) {
    return render(<FormContent {...defaultProps} {...props} />)
  }

  test('clicking "Close" button calls the dismiss prop', () => {
    const { getByText } = renderComponent()
    fireEvent.click(getByText('Close'))
    expect(defaultProps.dismiss).toHaveBeenCalledTimes(1)
  })

  test('clicking "Post" button calls the onPostClick prop', () => {
    const { getByText } = renderComponent()
    fireEvent.click(getByText('Post'))
    expect(defaultProps.onPostClick).toHaveBeenCalledTimes(1)
  })

  describe('default behavior', () => {
    it('hides the spinner', () => {
      const { queryByText } = renderComponent()
      expect(queryByText('Posting grades')).not.toBeInTheDocument()
    })

    it('shows the section toggle', () => {
      const { getByText } = renderComponent()
      expect(getByText('Specific Sections')).toBeInTheDocument()
    })

    it('shows the "post" button', () => {
      const { getByText } = renderComponent()
      expect(getByText('Post')).toBeInTheDocument()
    })

    it('shows the close button', () => {
      const { getByText } = renderComponent()
      expect(getByText('Close')).toBeInTheDocument()
    })

    it('enables "Post types" inputs', () => {
      const { container } = renderComponent()
      const inputs = container.querySelectorAll('input[type="radio"]')
      inputs.forEach(input => expect(input).not.toBeDisabled())
    })

    it('does not display a summary of unposted submissions', () => {
      const { queryByText } = renderComponent()
      expect(queryByText('Hidden')).not.toBeInTheDocument()
    })
  })

  describe('when postingGrades prop is true', () => {
    it('shows the spinner', () => {
      const { getByText } = renderComponent({ postingGrades: true })
      expect(getByText('Posting grades')).toBeInTheDocument()
    })

    it('hides the section toggle', () => {
      const { queryByText } = renderComponent({ postingGrades: true })
      expect(queryByText('Specific Sections')).not.toBeInTheDocument()
    })

    it('hides the "post" button', () => {
      const { queryByText } = renderComponent({ postingGrades: true })
      expect(queryByText('Post')).not.toBeInTheDocument()
    })

    it('hides the close button', () => {
      const { queryByText } = renderComponent({ postingGrades: true })
      expect(queryByText('Close')).not.toBeInTheDocument()
    })

    it('hides "Post types" inputs', () => {
      const { container } = renderComponent({ postingGrades: true })
      const inputs = container.querySelectorAll('input[type="radio"]')
      expect(inputs.length).toBe(0)
    })
  })

  describe('when grades are not published', () => {
    const unpublishedProps = {
      assignment: { ...defaultProps.assignment, gradesPublished: false },
    }

    it('disables "Post types" inputs', () => {
      const { container } = renderComponent(unpublishedProps)
      const inputs = container.querySelectorAll('input[type="radio"]')
      inputs.forEach(input => expect(input).toBeDisabled())
    })

    it('disables "Specific Section" toggle', () => {
      const { container } = renderComponent(unpublishedProps)
      const toggle = container.querySelector('input[type="checkbox"]')
      expect(toggle).toBeDisabled()
    })

    it('disables "Close" button', () => {
      const { getByText } = renderComponent(unpublishedProps)
      expect(getByText('Close').closest('button')).toBeDisabled()
    })

    it('disables "Post" button', () => {
      const { getByText } = renderComponent(unpublishedProps)
      expect(getByText('Post').closest('button')).toBeDisabled()
    })
  })

  describe('when some submissions are unposted', () => {
    it('displays a summary of unposted submissions', () => {
      const { getByText } = renderComponent({ unpostedCount: 1 })
      expect(getByText('Hidden')).toBeInTheDocument()
    })

    it('displays the number of unposted submissions', () => {
      const { getByText } = renderComponent({ unpostedCount: 2 })
      expect(getByText('2')).toBeInTheDocument()
    })

    it('displays the accessible message', () => {
      const { getByText } = renderComponent({ unpostedCount: 2 })
      expect(getByText('2 hidden')).toBeInTheDocument()
    })
  })

  describe('when sections are absent', () => {
    it('does not show the section toggle', () => {
      const { queryByText } = renderComponent({ sections: [] })
      expect(queryByText('Specific Sections')).not.toBeInTheDocument()
    })

    it('does not show sections when postBySections is false', () => {
      const { queryByText } = renderComponent({ sections: [], postBySections: false })
      expect(queryByText('Sophomores')).not.toBeInTheDocument()
    })
  })

  describe('Anonymous assignments', () => {
    it('disables "Specific Sections"', () => {
      const { container } = renderComponent({
        assignment: { ...defaultProps.assignment, anonymousGrading: true },
      })
      const toggle = container.querySelector('input[type="checkbox"]')
      expect(toggle).toBeDisabled()
    })
  })

  describe('PostTypes', () => {
    it('checks "Everyone" by default', () => {
      const { container } = renderComponent()
      const everyoneInput = Array.from(container.querySelectorAll('input[type="radio"]'))
        .find(input => input.value === EVERYONE)
      expect(everyoneInput).toBeChecked()
    })

    it('calls postTypeChanged when clicking another post type', () => {
      const { container } = renderComponent()
      const gradedInput = Array.from(container.querySelectorAll('input[type="radio"]'))
        .find(input => input.value !== EVERYONE)
      fireEvent.click(gradedInput)
      expect(defaultProps.postTypeChanged).toHaveBeenCalledTimes(1)
    })
  })

  describe('SpecificSections', () => {
    it('calls postBySectionsChanged when enabling "Specific Sections"', () => {
      const { container } = renderComponent()
      const toggle = container.querySelector('input[type="checkbox"]')
      fireEvent.click(toggle)
      expect(defaultProps.postBySectionsChanged).toHaveBeenCalledTimes(1)
    })

    it('calls sectionSelectionChanged when selecting a section', () => {
      const { getByText, container, debug } = renderComponent()

      const specificSectionsToggle = container.querySelector('input[id^="Checkbox_"][type="checkbox"]')
      fireEvent.click(specificSectionsToggle)

      const freshmenCheckbox = container.querySelectorAll('input[id^="Checkbox_"][type="checkbox"]')[1]
      fireEvent.click(freshmenCheckbox)

      expect(defaultProps.sectionSelectionChanged).toHaveBeenCalledTimes(1)
    })
  })
})