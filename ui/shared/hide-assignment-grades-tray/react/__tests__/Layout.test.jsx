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
import Layout from '../Layout'

const defaultProps = {
  assignment: {
    anonymousGrading: false,
    gradesPublished: true,
  },
  dismiss: () => {},
  hideBySections: true,
  hideBySectionsChanged: () => {},
  hidingGrades: false,
  onHideClick: () => {},
  sections: [
    {id: '2001', name: 'Freshmen'},
    {id: '2002', name: 'Sophomores'},
  ],
  sectionSelectionChanged: () => {},
  selectedSectionIds: [],
}

describe('HideAssignmentGradesTray Layout', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('unreleased grades message behavior', () => {
    const unreleasedMessage =
      'Hiding grades is not allowed because grades have not been released for this assignment.'

    it('shows unreleased grades message when gradesPublished is false', () => {
      render(
        <Layout
          {...defaultProps}
          assignment={{...defaultProps.assignment, gradesPublished: false}}
        />,
      )
      expect(screen.getByText(unreleasedMessage)).toBeInTheDocument()
    })

    it('hides unreleased grades message when gradesPublished is true', () => {
      render(<Layout {...defaultProps} />)
      expect(screen.queryByText(unreleasedMessage)).not.toBeInTheDocument()
    })
  })

  describe('browser refresh text behavior', () => {
    const refreshMessage = 'Hiding grades will refresh your browser. This may take a moment.'

    const setup = (props = {}) => {
      const assignment = {
        anonymousGrading: true,
        gradesPublished: true,
        ...props.assignment,
      }
      return render(<Layout {...defaultProps} {...props} assignment={assignment} />)
    }

    it('shows refresh text when conditions are met', () => {
      setup({containerName: 'SPEED_GRADER'})
      expect(screen.getByText(refreshMessage)).toBeInTheDocument()
    })

    it('hides refresh text when gradesPublished is false', () => {
      setup({
        containerName: 'SPEED_GRADER',
        assignment: {anonymousGrading: true, gradesPublished: false},
      })
      expect(screen.queryByText(refreshMessage)).not.toBeInTheDocument()
    })

    it('hides refresh text when anonymousGrading is false', () => {
      setup({
        containerName: 'SPEED_GRADER',
        assignment: {anonymousGrading: false, gradesPublished: true},
      })
      expect(screen.queryByText(refreshMessage)).not.toBeInTheDocument()
    })

    it('hides refresh text when containerName is not SPEED_GRADER', () => {
      setup({containerName: 'NOT_SPEED_GRADER'})
      expect(screen.queryByText(refreshMessage)).not.toBeInTheDocument()
    })
  })

  describe('anonymous assignment text behavior', () => {
    const anonymousMessage =
      'When hiding grades for anonymous assignments, grades will be hidden for everyone in the course. Anonymity will be re-applied.'

    const setup = (props = {}) => {
      const assignment = {
        anonymousGrading: true,
        gradesPublished: true,
        ...props.assignment,
      }
      const sections = props.sections || defaultProps.sections
      return render(<Layout {...defaultProps} assignment={assignment} sections={sections} />)
    }

    it('shows anonymous text when conditions are met', () => {
      setup()
      expect(screen.getByText(anonymousMessage)).toBeInTheDocument()
    })

    it('hides anonymous text when gradesPublished is false', () => {
      setup({assignment: {anonymousGrading: true, gradesPublished: false}})
      expect(screen.queryByText(anonymousMessage)).not.toBeInTheDocument()
    })

    it('hides anonymous text when sections are empty', () => {
      setup({sections: []})
      expect(screen.queryByText(anonymousMessage)).not.toBeInTheDocument()
    })

    it('hides anonymous text when anonymousGrading is false', () => {
      setup({assignment: {anonymousGrading: false, gradesPublished: true}})
      expect(screen.queryByText(anonymousMessage)).not.toBeInTheDocument()
    })
  })
})
