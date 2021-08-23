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
import LoggedOutTabs from '../LoggedOutTabs'
import {mockAssignment} from '@canvas/assignments/graphql/studentMocks'
import {render, waitFor} from '@testing-library/react'

describe('LoggedOutTabs', () => {
  it('renders component LoginActionPrompt', async () => {
    const assignment = await mockAssignment()
    const {getByText} = render(<LoggedOutTabs assignment={assignment} />)
    expect(await waitFor(() => getByText('Submission Locked'))).toBeInTheDocument()
    expect(await waitFor(() => getByText('Log in to submit'))).toBeInTheDocument()
  })
})
