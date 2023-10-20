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

import {Discussion} from '../../../../graphql/Discussion'
import {DiscussionTopicContainer} from '../DiscussionTopicContainer'
import {fireEvent, render} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'

jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))

beforeAll(() => {
  window.matchMedia = jest.fn().mockImplementation(() => {
    return {
      matches: true,
      media: '',
      onchange: null,
      addListener: jest.fn(),
      removeListener: jest.fn(),
    }
  })
})

describe('DiscussionTopicContainer', () => {
  const setup = (props, mocks) => {
    return render(
      <MockedProvider mocks={mocks}>
        <DiscussionTopicContainer {...props} />
      </MockedProvider>
    )
  }

  it('Renders the correct number of assignment overrides', async () => {
    const overrides = [
      {
        id: 'BXMzaWdebTVubC1x',
        _id: '1',
        dueAt: '',
        lockAt: '2021-09-03T23:59:59-06:00',
        unlockAt: '2021-03-21T00:00:00-06:00',
        title: 'assignment override 1',
      },
      {
        id: 'BXMzaWdebTVubC2x',
        _id: '2',
        dueAt: '',
        lockAt: '2021-09-03T23:59:59-06:00',
        unlockAt: '2021-03-21T00:00:00-06:00',
        title: 'assignment override 2',
      },
      {
        id: 'BXMzaWdebTVubC0x',
        _id: '3',
        dueAt: '',
        lockAt: '2021-09-03T23:59:59-06:00',
        unlockAt: '2021-03-21T00:00:00-06:00',
        title: 'assignment override 3',
      },
    ]

    const props = {discussionTopic: Discussion.mock({})}
    props.discussionTopic.assignment.assignmentOverrides.nodes = overrides
    props.discussionTopic.assignment.dueAt = '2021-09-03T23:59:59-06:00'
    props.discussionTopic.assignment.unlockAt = '2021-09-03T23:59:59-06:00'
    props.discussionTopic.assignment.lockAt = '2021-09-03T23:59:59-06:00'
    const container = setup(props)

    const showDueDatesButton = await container.findByTestId('show-due-dates-button')
    fireEvent.click(showDueDatesButton)
    const assignmentOverrides = await container.findAllByTestId('assignment-override-row')

    expect(assignmentOverrides.length).toBe(overrides.length + 1)
  })
})
