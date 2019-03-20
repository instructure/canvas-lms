/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import ContentTabs from '../ContentTabs'
import {mockAssignment} from '../../test-utils'
import React from 'react'
import {render} from 'react-testing-library'

it('renders the content tabs', () => {
  const {getAllByTestId} = render(<ContentTabs assignment={mockAssignment()} />)
  expect(getAllByTestId('assignment-2-student-content-tabs')).toHaveLength(1)
})

it('renders the tabs in the correct order', () => {
  const {getAllByRole, getByText} = render(<ContentTabs assignment={mockAssignment()} />)
  const tabs = getAllByRole('tab')

  expect(tabs).toHaveLength(3)
  expect(tabs[0]).toContainElement(getByText('Upload'))
  expect(tabs[1]).toContainElement(getByText('Comments'))
  expect(tabs[2]).toContainElement(getByText('Rubric'))
})
