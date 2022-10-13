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

import {render} from '@testing-library/react'
import React from 'react'
import {shallow} from 'enzyme'
import {MemoryRouter} from 'react-router-dom'
import Event from '../event'
import K from '../../../../constants'

describe('canvas_quizzes/events/views/event_stream/event', () => {
  it('renders EVT_SESSION_STARTED', () => {
    render(
      <MemoryRouter>
        <Event
          createdAt="2014-11-16T13:39:19Z"
          startedAt="2014-11-16T13:37:19Z"
          type={K.EVT_SESSION_STARTED}
        />
      </MemoryRouter>
    )
  })

  it('renders EVT_QUESTION_ANSWERED', () => {
    render(
      <MemoryRouter>
        <Event
          createdAt="2014-11-16T13:39:19Z"
          startedAt="2014-11-16T13:37:19Z"
          type={K.EVT_QUESTION_ANSWERED}
          questions={[{id: 'q1', questionType: K.Q_SHORT_ANSWER}]}
          data={[{quizQuestionId: 'q1', answer: 'hello world', answered: true}]}
        />
      </MemoryRouter>
    )
  })

  it('renders EVT_QUESTION_VIEWED', () => {
    render(
      <MemoryRouter>
        <Event
          createdAt="2014-11-16T13:39:19Z"
          startedAt="2014-11-16T13:37:19Z"
          type={K.EVT_QUESTION_VIEWED}
          questions={[{id: 'q1', questionType: K.Q_SHORT_ANSWER}]}
          data={[{quizQuestionId: 'q1', answer: 'hello world', answered: true}]}
        />
      </MemoryRouter>
    )
  })

  it('renders EVT_PAGE_BLURRED', () => {
    render(
      <MemoryRouter>
        <Event
          createdAt="2014-11-16T13:39:19Z"
          startedAt="2014-11-16T13:37:19Z"
          type={K.EVT_QUESTION_VIEWED}
          questions={[]}
          data={[]}
        />
      </MemoryRouter>
    )
  })

  it('renders EVT_PAGE_FOCUSED', () => {
    render(
      <MemoryRouter>
        <Event
          createdAt="2014-11-16T13:39:19Z"
          startedAt="2014-11-16T13:37:19Z"
          type={K.EVT_QUESTION_VIEWED}
          questions={[]}
          data={[]}
        />
      </MemoryRouter>
    )
  })

  it('renders EVT_QUESTION_FLAGGED', () => {
    render(
      <MemoryRouter>
        <Event
          createdAt="2014-11-16T13:39:19Z"
          startedAt="2014-11-16T13:37:19Z"
          type={K.EVT_QUESTION_FLAGGED}
          questions={[{id: 'q1', questionType: K.Q_SHORT_ANSWER}]}
          data={[{quizQuestionId: 'q1', answer: 'hello world', answered: true}]}
        />
      </MemoryRouter>
    )
  })

  describe('renders the correct icon with the correct color for the event', () => {
    const defaultProps = (props = {}) => ({
      createdAt: '2014-11-16T13:39:19Z',
      startedAt: '2014-11-16T13:37:19Z',
      questions: [],
      data: [],
      type: K.EVT_QUESTION_ANSWERED,
      ...props,
    })

    it('renders a green "complete" icon when the user focus the quiz', () => {
      const wrapper = shallow(
        <Event {...defaultProps({type: K.EVT_QUESTION_VIEWED, flag: K.EVT_FLAG_OK})} />
      )
      expect(wrapper.find('IconCompleteLine').props().color).toBe('success')
    })

    it('renders a red "trouble" icon when the user leaves the quiz', () => {
      const wrapper = shallow(
        <Event {...defaultProps({type: K.EVT_PAGE_BLURRED, flag: K.EVT_FLAG_WARNING})} />
      )
      expect(wrapper.find('IconTroubleLine').props().color).toBe('warning')
    })

    it('renders an "empty" grey icon when the user answers a question', () => {
      const wrapper = shallow(<Event {...defaultProps()} />)
      expect(wrapper.find('IconEmptyLine').props().color).toBe('secondary')
    })
  })
})
