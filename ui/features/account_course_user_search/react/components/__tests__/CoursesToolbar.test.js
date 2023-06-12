/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import CoursesToolbar from '../CoursesToolbar'
import {render} from '@testing-library/react'
import injectGlobalAlertContainers from '@canvas/util/react/testing/injectGlobalAlertContainers'

injectGlobalAlertContainers()

const props = {
  toggleSRMessage: () => {},
  onApplyFilters: () => {},
  onUpdateFilters: jest.fn(),
  isLoading: true,
  draftFilters: {
    enrollment_type: null,
    search_by: 'course',
    search_term: '',
    enrollment_term_id: '',
    blueprint: null,
    public: null,
  },
  errors: {},
  terms: {
    data: [
      {
        id: '1',
        name: 'Future Term 1',
        start_at: '2099-01-01',
        end_at: '3099-01-01',
      },
      {
        id: '2',
        name: 'Future Term 2',
        start_at: '2099-01-01',
      },
      {
        id: '3',
        name: 'Active Term 1',
        start_at: '1999-01-01',
        end_at: '3099-01-01',
      },
      {
        id: '4',
        name: 'Term With No Start Or End 1',
      },
      {
        id: '5',
        name: 'Past Term 1',
        end_at: '1999-01-01',
      },
    ],
    loading: false,
  },
}

describe('CoursesToolbar', () => {
  describe('Filtering', () => {
    it('onUpdateFilter is called when enrollment checkbox is clicked', () => {
      const {getByText} = render(<CoursesToolbar {...props} />)
      const enrollCheck = getByText('Hide courses without students')

      expect(props.draftFilters.enrollment_type).toBe(null)
      enrollCheck.click()
      expect(props.onUpdateFilters).toHaveBeenCalledWith({enrollment_type: ['student']})
    })

    it('onUpdateFilter is called when public courses checkbox is clicked', () => {
      const {getByText} = render(<CoursesToolbar {...props} />)
      const pubCheck = getByText('Show only public courses')

      expect(props.draftFilters.public).toBe(null)
      pubCheck.click()
      expect(props.onUpdateFilters).toHaveBeenCalledWith({public: true})
    })

    it('onUpdateFilter is called when blueprint courses checkbox is clicked', () => {
      const {getByText} = render(<CoursesToolbar {...props} />)
      const blueCheck = getByText('Show only blueprint courses')

      expect(props.draftFilters.blueprint).toBe(null)
      blueCheck.click()
      expect(props.onUpdateFilters).toHaveBeenCalledWith({blueprint: true})
    })

    it('terms are grouped correctly when term search is clicked', () => {
      const container = render(<CoursesToolbar {...props} />)
      container.getByText('Filter by term').click()

      const options = container.getAllByRole('option')

      const parsed = []
      options.forEach(e => {
        parsed.push(e.textContent)
      })

      expect(parsed).toStrictEqual([
        'All Terms',
        'Active Term 1',
        'Term With No Start Or End 1',
        'Future Term 1',
        'Future Term 2',
        'Past Term 1',
      ])
    })
  })
})
