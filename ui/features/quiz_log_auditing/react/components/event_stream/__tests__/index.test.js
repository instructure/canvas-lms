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

import {act, render, fireEvent} from '@testing-library/react'
import React from 'react'
import { MemoryRouter } from 'react-router-dom'
import EventStream from '../index'
import assertChange from 'chai-assert-change'
import K from '../../../../constants'

describe('canvas_quizzes/events/views/event_stream', () => {
  it('renders', () => {
    render(
      <MemoryRouter>
        <EventStream
          events={[
            {
              id: 'e1',
              createdAt: "2014-11-16T13:39:19Z",
              startedAt: "2014-11-16T13:37:19Z",
              type: K.EVT_SESSION_STARTED,
            }
          ]}
        />
      </MemoryRouter>
    )
  })
})
