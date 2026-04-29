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

import React from 'react'
import {render} from '@testing-library/react'
import {Button} from '@instructure/ui-buttons'
import fakeENV from '@canvas/test-utils/fakeENV'
import NewCourseModal from '../NewCourseModal'
import AccountsTreeStore from '../../store/AccountsTreeStore'

const terms = {
  data: [
    {
      id: '1',
      name: 'First Term',
      start_at: '2025-01-01T00:00:00Z',
      end_at: '2025-05-01T00:00:00Z',
    },
  ],
  loading: false,
}

const children = <Button>Add Course</Button>

describe('NewCourseModal', () => {
  beforeEach(() => {
    fakeENV.setup({LOCALES: ['en']})

    // Set up the flash_screenreader_holder element that SearchableSelect expects
    const liveRegion = document.createElement('div')
    liveRegion.id = 'flash_screenreader_holder'
    liveRegion.setAttribute('role', 'alert')
    liveRegion.setAttribute('aria-live', 'assertive')
    liveRegion.setAttribute('aria-atomic', 'true')
    liveRegion.style.position = 'absolute'
    liveRegion.style.left = '-10000px'
    liveRegion.style.width = '1px'
    liveRegion.style.height = '1px'
    liveRegion.style.overflow = 'hidden'
    document.body.appendChild(liveRegion)
  })

  afterEach(() => {
    fakeENV.teardown()

    // Clean up the live region element
    const liveRegion = document.getElementById('flash_screenreader_holder')
    if (liveRegion) {
      document.body.removeChild(liveRegion)
    }
  })

  // NewCourseModal uses the old model of stores (CoursesStore)
  // so it's easier to test via selenium (new_course_search_spec.rb)
  // than make a top-level test in AccountCourseUserSearch.test.tsx
  it('renders modal after clicking button', () => {
    const {getByText} = render(<NewCourseModal terms={terms}>{children}</NewCourseModal>)

    // open modal
    getByText('Add Course').click()
    expect(getByText('Add a New Course')).toBeInTheDocument()
    expect(getByText('Course Name')).toBeInTheDocument()
    expect(getByText('Reference Code')).toBeInTheDocument()
    expect(getByText('Enrollment Term')).toBeInTheDocument()
    expect(getByText('Subaccount')).toBeInTheDocument()
  })

  it('handles accounts with null names gracefully', () => {
    const mockGetTree = vi.spyOn(AccountsTreeStore, 'getTree').mockReturnValue({
      loading: false,
      accounts: [
        {
          id: '1',
          name: 'Valid Account',
          subAccounts: [],
        },
        {
          id: '2',
          name: null as any, // Force null name to test the scenario
          subAccounts: [],
        },
      ],
    })

    const {getByText} = render(<NewCourseModal terms={terms}>{children}</NewCourseModal>)

    // This should trigger the renderAccountOptions function
    getByText('Add Course').click()
    expect(getByText('Add a New Course')).toBeInTheDocument()
    expect(getByText('Subaccount')).toBeInTheDocument()

    mockGetTree.mockRestore()
  })
})
