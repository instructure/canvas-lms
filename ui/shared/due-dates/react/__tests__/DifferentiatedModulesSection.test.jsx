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
import DifferentiatedModulesSection from '../DifferentiatedModulesSection'
import AssignmentOverrideCollection from '@canvas/assignments/backbone/collections/AssignmentOverrideCollection'

describe('DifferentiatedModulesSection', () => {
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
        onSync: () => { },
        importantDates: false,
        assignmentName: 'First Assignment',
        assignmentId: '1',
        type: 'assignment',
        pointsPossible: '10',
        overrides: assignmentcollection.models,
        defaultSectionId: 0,
    }

    it('renders', () => {
        const {getByText} = render(<DifferentiatedModulesSection {...props} />)
        expect(
            getByText('Manage Assign To')
          ).toBeInTheDocument()
        expect(
            getByText(`${props.overrides.length} Assigned`)
          ).toBeInTheDocument()
    })

    it('opens ItemAssignToTray', () => {
        const {getByText, getByTestId} = render(<DifferentiatedModulesSection {...props} />)
        getByTestId('manage-assign-to').click()
        expect(getByText('First Assignment')).toBeInTheDocument()
    })

    it('calls onSync when saving changes made in ItemAssignToTray', () => {
        const onSyncMock = jest.fn()
        const {getByRole, getByTestId} = render(<DifferentiatedModulesSection {...props} onSync={onSyncMock} />)

        getByTestId('manage-assign-to').click()
        getByRole('button', {name: 'Save'}).click()
        expect(onSyncMock).toHaveBeenCalledWith(assignmentcollection.models, props.importantDates)
    })

    describe('important dates', ()=>{
        beforeAll(()=>{
            global.ENV = {
                K5_SUBJECT_COURSE: true
            }
        })

        it('does not render the option for non-assignment items', ()=>{
            const {queryByTestId} = render(<DifferentiatedModulesSection {...props} type="quiz" />)

            expect(queryByTestId('important_dates')).not.toBeInTheDocument()
        })

        it('calls onSync with the importantDates flag when checking/unchecking the option', () => {
            const onSyncMock = jest.fn()
            const {getByTestId} = render(<DifferentiatedModulesSection {...props} onSync={onSyncMock} />)

            getByTestId('important_dates').click()
            expect(onSyncMock).toHaveBeenCalledWith(undefined, true)

            getByTestId('important_dates').click()
            expect(onSyncMock).toHaveBeenCalledWith(undefined, false)
        })

        it('disables the importantDates check when no due dates are set', () => {
            const override = assignmentcollection.models[0]
            override.set('due_at', '')
            const {getByTestId} = render(<DifferentiatedModulesSection {...props} overrides={[override]} />)

            expect(getByTestId('important_dates')).toBeDisabled()
        })
    })
})