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
import {assignLocation} from '@canvas/util/globalUtils'
import {render, screen} from '@testing-library/react'
import {Main} from '../Main'

jest.mock('@canvas/util/globalUtils', () => ({
  assignLocation: jest.fn(),
}))

describe('Main', () => {
  beforeAll(() => {
    ENV.COURSE_ID = '3'
  })

  it('navigates to student view on Learner Preview button click', () => {
    render(<Main />)
    const previewButton = screen.getByText("Learner Preview")
    previewButton.click()

    expect(assignLocation).toHaveBeenCalledWith(`/courses/${ENV.COURSE_ID}/student_view?preview=true`)
  })
})
