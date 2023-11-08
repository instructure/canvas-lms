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

import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {Discussion} from '../../../../graphql/Discussion'
import {DiscussionEntry} from '../../../../graphql/DiscussionEntry'
import {DiscussionTopicRepliesContainer} from '../DiscussionTopicRepliesContainer'
import {fireEvent, render} from '@testing-library/react'
import {getDiscussionEntryAllRootEntriesQueryMock} from '../../../../graphql/Mocks'
import {MockedProvider} from '@apollo/react-testing'
import {PageInfo} from '../../../../graphql/PageInfo'
import React from 'react'

jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: () => ({desktop: {maxWidth: '1024px'}}),
}))
jest.mock('../../../utils/constants', () => ({
  ...jest.requireActual('../../../utils/constants'),
  AUTO_MARK_AS_READ_DELAY: 0,
}))

describe('DiscussionTopicRepliesContainer', () => {
  beforeAll(() => {
    window.ENV = {
      course_id: '1',
      per_page: 20,
    }

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

  const defaultProps = () => {
    return {
      discussionTopic: {
        ...Discussion.mock(),
        discussionEntriesConnection: {
          nodes: [
            DiscussionEntry.mock({
              entryParticipant: {read: false, forcedReadState: null, rating: false},
            }),
          ],
          pageInfo: PageInfo.mock(),
          __typename: 'DiscussionEntriesConnection',
        },
      },
      searchTerm: '',
    }
  }

  const setup = (props, mocks) => {
    return render(
      <MockedProvider mocks={mocks}>
        <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
          <DiscussionTopicRepliesContainer {...props} />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
  }

  it('should render', () => {
    const {container} = setup(defaultProps())
    expect(container).toBeTruthy()
  })

  it('should render when threads are empty', () => {
    const {container} = setup({
      ...defaultProps(),
      threads: [],
    })
    expect(container).toBeTruthy()
  })

  it('renders the pagination component if there are more than 1 pages', () => {
    const {getByTestId} = setup(defaultProps())
    expect(getByTestId('pagination')).toBeInTheDocument()
  })

  it('does not render the pagination component if there is only 1 page', () => {
    const props = defaultProps()
    props.discussionTopic.entriesTotalPages = 1
    const {queryByTestId} = setup(props)
    expect(queryByTestId('pagination')).toBeNull()
  })
})
