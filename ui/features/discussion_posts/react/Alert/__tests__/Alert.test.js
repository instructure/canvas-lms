/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {Alert} from '../Alert'

import React from 'react'

import {render} from '@testing-library/react'

const setup = () => {
  return render(
    <Alert contextDisplayText="Section 4" pointsPossible={7} dueAtDisplayText="Jan 26 11:49pm" />
  )
}

describe('Alert', () => {
  it('displays alert info', () => {
    const {queryByText} = setup()
    expect(queryByText('Section 4')).toBeTruthy()
    expect(queryByText('This is a graded discussion: 7 points possible')).toBeTruthy()
    expect(queryByText('Due: Jan 26 11:49pm')).toBeTruthy()
  })
})
