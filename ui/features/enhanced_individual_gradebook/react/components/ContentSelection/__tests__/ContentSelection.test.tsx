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
import {MockedProvider} from '@apollo/react-testing'
import {render} from '@testing-library/react'
import ContentSelection from '..'
import {defaultSortableStudents, makeContentSelectionProps} from './fixtures'

describe('Content Selection', () => {
  describe('student dropdown', () => {
    it('displays the sortableName in the student dropdown', () => {
      const props = makeContentSelectionProps({students: defaultSortableStudents})
      const {getByTestId} = render(
        <MockedProvider>
          <ContentSelection {...props} />
        </MockedProvider>
      )
      const studentDropdown = getByTestId('content-selection-student-select')
      expect(studentDropdown).toHaveTextContent('Last, First')
      expect(studentDropdown).toHaveTextContent('Last2, First2')
    })
  })
})
