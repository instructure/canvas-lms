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

import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import Essay from '../essay'
import assertChange from 'chai-assert-change'

describe('canvas_quizzes/events/views/question_inspector/answers/essay', () => {
  it('renders', () => {
    render(<Essay answer="yea!" />)
    expect(document.body.textContent).toMatch('yea!')
  })

  it('toggles between views', () => {
    const {getByText} = render(<Essay answer="<span id='custom-el'>yea!</span>" />)

    assertChange({
      fn: () => fireEvent.click(getByText('View HTML')),
      of: () => !!document.getElementById('custom-el'),
      from: false,
      to: true,
    })
  })
})
