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
import NewCourseModal from '../NewCourseModal'
import {Button} from '@instructure/ui-buttons'

const terms = {
    data: [{
        id: '1',
        name: 'First Term',
        start_at: '2025-01-01T00:00:00Z',
        end_at: '2025-05-01T00:00:00Z'
    }],
    loading: false
}

const children = <Button>Add Course</Button>

describe ('NewCourseModal', () => {

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
})