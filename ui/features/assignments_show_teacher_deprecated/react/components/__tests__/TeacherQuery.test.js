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

import {waitFor} from '@testing-library/react'
import {mockAssignment} from '../../test-utils'
import {renderTeacherQuery} from './integration/integration-utils'

describe('TeacherQuery', () => {
  it.skip('renders a loading spinner and then the assignment with data from the query', async () => {
    const assignment = mockAssignment()
    const {getAllByText, getByTitle} = renderTeacherQuery(assignment)
    expect(getByTitle('Loading...')).toBeInTheDocument()
    expect(await waitFor(() => getAllByText(assignment.name)[0])).toBeInTheDocument()
  })

  it.skip('renders a problem screen on a bad graphql query', () => {})
})
