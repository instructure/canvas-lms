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
import {render} from '@testing-library/react'
import DifferentiatedModulesLink from '../DifferentiatedModulesLink'
import AssignmentOverrideCollection from '@canvas/assignments/backbone/collections/AssignmentOverrideCollection'

describe('DifferentiatedModulesLink', () => {
    const assignmentcollection = new AssignmentOverrideCollection([{
        id: "100",
        assignment_id: "5",
        title: "Section A",
        due_at: "2024-01-17T23:59:59-07:00",
        all_day: true,
        all_day_date: "2024-01-17",
        unlock_at: null,
        lock_at: null,
        course_section_id: "5",
        due_at_overridden: true,
        unlock_at_overridden: true,
        lock_at_overridden: true,
      }])

    const props = {
        onSave: () => { },
        assignmentName: 'First Assignment',
        assignmentId: '1',
        type: 'assignment',
        pointsPossible: '10',
        overrides: assignmentcollection.models,
        defaultSectionId: 0,
    }

    it('renders', () => {
        const {getByText} = render(<DifferentiatedModulesLink {...props} />)
        expect(
            getByText('Manage Assign To')
          ).toBeInTheDocument()
        expect(
            getByText(`${props.overrides.length} Assigned`)
          ).toBeInTheDocument()
    })

    it('opens ItemAssignToTray', () => {
        const {getByText, getByTestId} = render(<DifferentiatedModulesLink {...props} />)
        getByTestId('manage-assign-to').click()
        expect(getByText('First Assignment')).toBeInTheDocument()
    })

    it('calls onSave when saving changes made in ItemAssignToTray', () => {
        const onSaveMock = jest.fn()
        const {getByRole, getByTestId} = render(<DifferentiatedModulesLink {...props} onSave={onSaveMock} />)

        getByTestId('manage-assign-to').click()
        getByRole('button', {name: 'Save'}).click()
        expect(onSaveMock).toHaveBeenCalled()
    })
})