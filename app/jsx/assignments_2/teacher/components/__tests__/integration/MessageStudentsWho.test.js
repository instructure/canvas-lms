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

import {fireEvent, waitForElement} from 'react-testing-library'
import {renderTeacherView} from './integration-utils'
import {mockAssignment, itBehavesLikeADialog} from '../../../test-utils'

jest.mock('jsx/shared/rce/RichContentEditor')

describe('MessageStudentsWho integration', () => {
  itBehavesLikeADialog({
    render: renderTeacherView,
    getOpenDialogElt: fns => fns.getByText(/unsubmitted/i),
    confirmDialogOpen: fns => fns.getByText('Message Students Who...'),
    getCancelDialogElt: fns => fns.getByText(/cancel/i)
  })

  it('shows the message students who dialog when the unsubmitted button is clicked', async () => {
    const {getByText, queryByText} = await renderTeacherView()
    expect(queryByText('Message Students Who...')).toBeNull()
    fireEvent.click(getByText(/unsubmitted/i))
    expect(await waitForElement(() => getByText('Message Students Who...'))).toBeInTheDocument()
  })

  it('shows the message students who dialog when the message students who button is clicked', async () => {
    const {getByText} = await renderTeacherView(mockAssignment({submissionTypes: ['none']}))
    fireEvent.click(getByText(/message students/i))
    expect(await waitForElement(() => getByText('Message Students Who...'))).toBeInTheDocument()
  })
})
