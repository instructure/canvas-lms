/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import FormContent from '../FormContent'

describe('FormContent', () => {
  const defaultProps = {
    assignment: {
      anonymousGrading: false,
      gradesPublished: true,
      id: '2001',
      name: 'Math 1.1',
    },
    dismiss: jest.fn(),
    hideBySections: true,
    hideBySectionsChanged: jest.fn(),
    hidingGrades: false,
    onHideClick: jest.fn(),
    sections: [
      {id: '2001', name: 'Freshmen'},
      {id: '2002', name: 'Sophomores'},
    ],
    sectionSelectionChanged: jest.fn(),
    selectedSectionIds: [],
  }

  const renderComponent = (props = {}) => {
    return render(<FormContent {...defaultProps} {...props} />)
  }

  it('calls dismiss when clicking Close button', async () => {
    const dismiss = jest.fn()
    renderComponent({dismiss})
    await userEvent.click(screen.getByRole('button', {name: 'Close'}))
    expect(dismiss).toHaveBeenCalledTimes(1)
  })

  it('calls onHideClick when clicking Hide button', async () => {
    const onHideClick = jest.fn()
    renderComponent({onHideClick})
    await userEvent.click(screen.getByRole('button', {name: 'Hide'}))
    expect(onHideClick).toHaveBeenCalledTimes(1)
  })

  describe('default behavior', () => {
    beforeEach(() => {
      renderComponent()
    })

    it('does not show the spinner', () => {
      expect(screen.queryByRole('img', {name: 'Hiding grades'})).not.toBeInTheDocument()
    })

    it('shows the section toggle', () => {
      expect(screen.getByRole('checkbox', {name: 'Specific Sections'})).toBeInTheDocument()
    })

    it('shows the description', () => {
      expect(
        screen.getByText(
          'While the grades for this assignment are hidden, students will not receive new notifications about or be able to see:',
        ),
      ).toBeInTheDocument()
    })

    it('shows the Hide button', () => {
      expect(screen.getByRole('button', {name: 'Hide'})).toBeInTheDocument()
    })

    it('shows the Close button', () => {
      expect(screen.getByRole('button', {name: 'Close'})).toBeInTheDocument()
    })
  })

  describe('when hiding grades', () => {
    beforeEach(() => {
      renderComponent({hidingGrades: true})
    })

    it('shows the spinner', () => {
      expect(screen.getByRole('img', {name: 'Hiding grades'})).toBeInTheDocument()
    })

    it('hides the section toggle', () => {
      expect(screen.queryByRole('checkbox', {name: 'Specific Sections'})).not.toBeInTheDocument()
    })

    it('hides the Hide button', () => {
      expect(screen.queryByRole('button', {name: 'Hide'})).not.toBeInTheDocument()
    })

    it('hides the Close button', () => {
      expect(screen.queryByRole('button', {name: 'Close'})).not.toBeInTheDocument()
    })
  })

  describe('when grades are not published', () => {
    beforeEach(() => {
      renderComponent({
        assignment: {
          ...defaultProps.assignment,
          gradesPublished: false,
        },
      })
    })

    it('disables the Specific Sections toggle', () => {
      expect(screen.getByRole('checkbox', {name: 'Specific Sections'})).toBeDisabled()
    })

    it('disables the Close button', () => {
      expect(screen.getByRole('button', {name: 'Close'})).toBeDisabled()
    })

    it('disables the Hide button', () => {
      expect(screen.getByRole('button', {name: 'Hide'})).toBeDisabled()
    })

    it('shows the description', () => {
      expect(
        screen.getByText(
          'While the grades for this assignment are hidden, students will not receive new notifications about or be able to see:',
        ),
      ).toBeInTheDocument()
    })
  })

  describe('when sections are absent', () => {
    it('does not show the section toggle when no sections exist', () => {
      renderComponent({sections: []})
      expect(screen.queryByRole('checkbox', {name: 'Specific Sections'})).not.toBeInTheDocument()
    })

    it('does not show sections when hideBySections is false', () => {
      renderComponent({hideBySections: false})
      expect(screen.queryByText('Sophomores')).not.toBeInTheDocument()
    })
  })

  describe('with anonymous assignments', () => {
    beforeEach(() => {
      renderComponent({
        assignment: {
          ...defaultProps.assignment,
          anonymousGrading: true,
        },
      })
    })

    it('disables the Specific Sections toggle', () => {
      expect(screen.getByRole('checkbox', {name: 'Specific Sections'})).toBeDisabled()
    })
  })

  describe('section selection', () => {
    it('calls hideBySectionsChanged when enabling Specific Sections', async () => {
      const hideBySectionsChanged = jest.fn()
      renderComponent({hideBySectionsChanged})
      await userEvent.click(screen.getByRole('checkbox', {name: 'Specific Sections'}))
      expect(hideBySectionsChanged).toHaveBeenCalledTimes(1)
    })

    it('calls sectionSelectionChanged when selecting a section', async () => {
      const sectionSelectionChanged = jest.fn()
      renderComponent({sectionSelectionChanged})
      await userEvent.click(screen.getByRole('checkbox', {name: 'Specific Sections'}))
      await userEvent.click(screen.getByRole('checkbox', {name: 'Freshmen'}))
      expect(sectionSelectionChanged).toHaveBeenCalledTimes(1)
    })
  })
})
