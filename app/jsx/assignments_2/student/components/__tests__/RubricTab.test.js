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
import {render} from '@testing-library/react'
import {rubric} from '../RubricProps'
import Rubric from '../../../../rubrics/Rubric'

describe('RubricTab', () => {
  it('contains the rubric criteria heading', () => {
    const {getByText} = render(<Rubric rubric={rubric} />)
    expect(getByText('Criteria')).toBeInTheDocument()
  })

  it('contains the rubric ratings heading', () => {
    const {getByText} = render(<Rubric rubric={rubric} />)
    expect(getByText('Ratings')).toBeInTheDocument()
  })

  it('contains the rubric points heading', () => {
    const {getByText} = render(<Rubric rubric={rubric} />)
    expect(getByText('Pts')).toBeInTheDocument()
  })
})
