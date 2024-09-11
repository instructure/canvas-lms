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

import {fireEvent, waitFor} from '@testing-library/react'
import {renderTeacherView} from './integration-utils'
import {closest, mockAssignment, itBehavesLikeADialog} from '../../../test-utils'

jest.mock('@canvas/rce/RichContentEditor')

describe('MessageStudentsWho integration', () => {
  itBehavesLikeADialog({
    render: () => renderTeacherView(mockAssignment(), [], {}, 'Students'),
    getOpenDialogElt: fns => fns.getByText(/message students/i),
    confirmDialogOpen: fns => fns.getByText('Message Students Who...'),
    getCancelDialogElt: fns => fns.getByText(/cancel/i),
  })

  it('shows the message students who dialog when the message students who button is clicked', async () => {
    const {getByText, getAllByText} = await renderTeacherView(
      mockAssignment({submissionTypes: ['none']})
    )
    fireEvent.click(getAllByText(/students/i)[0])
    fireEvent.click(closest(getByText(/message students/i), 'button'))
    expect(await waitFor(() => getByText('Message Students Who...'))).toBeInTheDocument()
  })
})
