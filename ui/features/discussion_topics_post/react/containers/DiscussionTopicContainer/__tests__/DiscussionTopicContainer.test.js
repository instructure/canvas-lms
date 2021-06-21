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
import {ApolloProvider} from 'react-apollo'
import {DiscussionTopicContainer} from '../DiscussionTopicContainer'
import {fireEvent, render} from '@testing-library/react'
import {getEditUrl, getSpeedGraderUrl, getPeerReviewsUrl} from '../../../utils'
import {graphql} from 'msw'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import React from 'react'
import {waitFor} from '@testing-library/dom'
import {Discussion} from '../../../../graphql/Discussion'

jest.mock('@canvas/rce/RichContentEditor')

const defaultTopic = Discussion.mock()

const discussionTopicMock = {
  discussionTopic: {
    _id: '1',
    id: 'VXNlci0x',
    title: 'Discussion Topic One',
    author: {
      name: 'Chawn Neal',
      avatarUrl: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
    },
    message: '<p> This is the Discussion Topic. </p>',
    postedAt: '2021-04-05T13:40:50Z',
    subscribed: true,
    published: true,
    canUnpublish: true,
    entryCounts: {
      repliesCount: 24,
      unreadCount: 4
    },
    assignment: {
      _id: '1337',
      dueAt: '2021-04-05T13:40:50Z',
      pointsPossible: 5
    },
    permissions: {
      update: true,
      delete: true,
      speedGrader: true,
      moderateForum: true,
      peerReview: true,
      openForComments: false,
      closeForComments: true,
      manageContent: true,
      readAsAdmin: true
    }
  }
}

describe('DiscussionTopicContainer', () => {
  const server = mswServer(handlers)
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()
  const assignMock = jest.fn()
  let liveRegion = null

  beforeAll(() => {
    delete window.location
    window.location = {assign: assignMock}
    window.ENV = {
      context_asset_string: 'course_1',
      course_id: '1',
      discussion_topic_menu_tools: [{base_url: 'example.com'}]
    }

    if (!document.getElementById('flash_screenreader_holder')) {
      liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }

    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()
  })

  afterEach(() => {
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
    assignMock.mockClear()
    server.resetHandlers()
  })

  afterAll(() => {
    if (liveRegion) {
      liveRegion.remove()
    }

    server.close()
    // eslint-disable-next-line no-undef
    fetchMock.enableMocks()
  })

  const setup = props => {
    return render(
      <ApolloProvider client={mswClient}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <DiscussionTopicContainer {...props} />
        </AlertManagerContext.Provider>
      </ApolloProvider>
    )
  }
  it('publish button is readonly if canUnpublish is false', async () => {
    const {getByText} = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, canUnpublish: false}
    })

    expect(getByText('Published').closest('button').hasAttribute('disabled')).toBeTruthy()
  })

  it('renders a special alert for differentiated group assignments for readAsAdmin', async () => {
    const container = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        groupSet: {name: 'test'},
        assignment: {onlyVisibleToOverrides: true}
      }
    })
    expect(await container.findByTestId('differentiated-alert')).toBeTruthy()
  })

  it('non-readAsAdmin does not see Diff. Group Assignments alert', async () => {
    const container = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        groupSet: {name: 'test'},
        assignment: {onlyVisibleToOverrides: true},
        permissions: {readAsAdmin: false}
      }
    })
    expect(await container.findByTestId('graded-discussion-info')).toBeTruthy()
    expect(await container.queryByTestId('differentiated-alert')).toBeFalsy()
  })

  it('renders without optional props', async () => {
    const container = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, assignment: {}}
    })
    expect(await container.queryByText('24 replies, 4 unread')).toBeTruthy()

    expect(await container.queryByText('No Due Date')).toBeTruthy()

    expect(
      await container.queryByText('This is a graded discussion: 0 points possible')
    ).toBeTruthy()
  })

  it('renders infoText only when there are replies', async () => {
    const container = setup(discussionTopicMock)
    const infoText = await container.findByTestId('replies-counter')
    expect(infoText).toHaveTextContent('24 replies, 4 unread')
  })

  it('does not render unread when there are none', async () => {
    const container = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, unreadCount: 0}
    })
    const infoText = await container.findByTestId('replies-counter')
    expect(infoText).toHaveTextContent('24 replies')
  })

  it('renders Graded info when assignment info exists', async () => {
    const container = setup(discussionTopicMock)
    const gradedDiscussionInfo = await container.findByTestId('graded-discussion-info')
    expect(gradedDiscussionInfo).toHaveTextContent('This is a graded discussion: 5 points possible')
  })

  it('renders Graded info when isGraded', async () => {
    const {findByTestId} = setup(discussionTopicMock)
    const gradedDiscussionInfo = await findByTestId('graded-discussion-info')
    expect(gradedDiscussionInfo).toHaveTextContent('This is a graded discussion: 5 points possible')
  })

  it('should be able to send to edit page when canUpdate', async () => {
    const {getByTestId, getByText} = setup(discussionTopicMock)
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Edit'))

    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith(getEditUrl('1', '1'))
    })
  })

  it('should be able to send to peer reviews page when canPeerReview', async () => {
    const {getByTestId, getByText} = setup(discussionTopicMock)
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Peer Reviews'))

    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith(getPeerReviewsUrl('1', '1337'))
    })
  })

  it('Should be able to delete topic', async () => {
    window.confirm = jest.fn(() => true)
    const {getByTestId, getByText} = setup(discussionTopicMock)
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Delete'))

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('The discussion topic was successfully deleted.')
    )
    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith('/courses/1/discussion_topics')
    })
  })

  it('Should not be able to delete the topic if does not have permission', async () => {
    const {getByTestId, queryByTestId} = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {copyAndSendTo: true, delete: false}
      }
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(queryByTestId('delete')).toBeNull()
  })

  it('Should not show discussion topic menu if no appropriate permissions', async () => {
    const {queryByTestId} = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {}
      }
    })
    expect(queryByTestId('discussion-post-menu-trigger')).toBeNull()
  })

  it('Should be able to open SpeedGrader', async () => {
    const {getByTestId, getByText} = setup(discussionTopicMock)
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Open in Speedgrader'))

    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith(getSpeedGraderUrl('1', '1337'))
    })
  })

  it('Should find due date text for assignment', async () => {
    const container = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, permissions: {readAsAdmin: false}}
    })
    expect(await container.findByText('Due: Apr 5 1:40pm')).toBeTruthy()
  })

  it('Should not be able to see post menu if no permissions', () => {
    const {queryByTestId} = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, permissions: {speedGrader: false}}
    })

    expect(queryByTestId('discussion-post-menu-trigger')).toBeNull()
  })

  it.skip('Renders Add Rubric in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, permissions: {addRubric: true}}
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Add Rubric')).toBeInTheDocument()
  })

  it.skip('Renders Show Rubric in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, permissions: {showRubric: true}}
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Show Rubric')).toBeInTheDocument()
  })

  it('Renders Open for Comments in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {openForComments: true}
      }
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Open for Comments')).toBeInTheDocument()
  })

  it('Renders Close for Comments in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {closeForComments: true}
      }
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Close for Comments')).toBeInTheDocument()
  })

  it('Renders Copy To and Send To in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {copyAndSendTo: true}
      }
    })

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Copy To...')).toBeInTheDocument()
    expect(getByText('Send To...')).toBeInTheDocument()
  })

  it('renders a modal to send content', async () => {
    const container = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {copyAndSendTo: true}
      }
    })
    const kebob = await container.findByTestId('discussion-post-menu-trigger')
    fireEvent.click(kebob)
    const sendToButton = await container.findByText('Send To...')
    fireEvent.click(sendToButton)
    expect(await container.findByText('Send to:')).toBeTruthy()
  })

  // eslint-disable-next-line jest/no-disabled-tests
  it.skip('renders a modal to copy content', async () => {
    const container = setup({
      discussionTopic: {
        ...discussionTopicMock.discussionTopic,
        permissions: {copyAndSendTo: true}
      }
    })
    const kebob = await container.findByTestId('discussion-post-menu-trigger')
    fireEvent.click(kebob)
    const copyToButton = await container.findByText('Copy To...')
    fireEvent.click(copyToButton)
    expect(await container.findByText('Select a Course')).toBeTruthy()
  })

  it('can send users to Commons if they can manageContent', async () => {
    const {getByTestId, getByText} = setup(discussionTopicMock)
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Share to Commons'))

    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith(
        `example.com&discussion_topics%5B%5D=${discussionTopicMock.discussionTopic._id}`
      )
    })
  })

  it('renders a reply button if user has reply permission true', async () => {
    const container = setup({discussionTopic: {...defaultTopic}})
    await waitFor(() =>
      expect(container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
    )
    expect(await container.findByTestId('discussion-topic-reply')).toBeInTheDocument()
  })

  it('does not render a reply button if user has reply permission false', async () => {
    defaultTopic.permissions.reply = false
    server.use(
      graphql.query('GetDiscussionQuery', (req, res, ctx) => {
        return res.once(
          ctx.data({
            legacyNode: {...defaultTopic}
          })
        )
      })
    )
    const container = setup({discussionTopic: {...defaultTopic}})
    await waitFor(() =>
      expect(container.getByText('This is a Discussion Topic Message')).toBeInTheDocument()
    )

    await waitFor(() => expect(container.queryByTestId('discussion-topic-reply')).toBeNull())
    defaultTopic.permissions.reply = true
  })

  it('should find "Super Group" group name', async () => {
    const container = setup({discussionTopic: {...defaultTopic}})
    expect(await container.queryByText('Super Group')).toBeFalsy()
    fireEvent.click(await container.queryByTestId('groups-menu-btn'))
    await waitFor(() => expect(container.queryByText('Super Group')).toBeTruthy())
  })

  it('should show groups menu when discussion has no child topics but has sibling topics', async () => {
    // defaultTopic has a root topic which has a child topic named Super Group
    // we are only removing the child topic from defaultTopic itself, not its root topic
    const container = setup({discussionTopic: {...defaultTopic, childTopics: null}})
    expect(await container.queryByText('Super Group')).toBeFalsy()
    fireEvent.click(await container.queryByTestId('groups-menu-btn'))
    await waitFor(() => expect(container.queryByText('Super Group')).toBeTruthy())
  })

  it('should not render group menu button when there is child topics but no group set', async () => {
    const container = setup({
      discussionTopic: {...discussionTopicMock.discussionTopic, groupSet: null}
    })

    await expect(container.queryByTestId('groups-menu-btn')).toBeFalsy()
  })

  it('Should be able to close for comments', async () => {
    const {getByText, getByTestId} = setup(discussionTopicMock)
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Close for Comments'))

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith(
        'You have successfully updated the discussion topic.'
      )
    )
  })

  it('Should be able to open for comments', async () => {
    const testDiscussionTopicMock = discussionTopicMock
    testDiscussionTopicMock.discussionTopic.permissions.openForComments = true
    testDiscussionTopicMock.discussionTopic.permissions.closeForComments = false

    const {getByText, getByTestId} = setup(testDiscussionTopicMock)
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Open for Comments'))

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith(
        'You have successfully updated the discussion topic.'
      )
    )
  })

  it('Should find due date text', async () => {
    const container = setup(discussionTopicMock)
    expect(await container.findByText('Everyone: Due Apr 5 1:40pm')).toBeTruthy()
  })

  it('Should find "Show Due Dates" link button', async () => {
    const props = {discussionTopic: Discussion.mock({})}
    const container = setup(props)
    expect(await container.findByText('Show Due Dates (2)')).toBeTruthy()
  })

  it('Should find due date text for "assignment override 3"', async () => {
    const overrides = [
      {
        id: 'BXMzaWdebTVubC0x',
        _id: '3',
        dueAt: '2021-04-05T13:40:50Z',
        lockAt: '2021-09-03T23:59:59-06:00',
        unlockAt: '2021-03-21T00:00:00-06:00',
        title: 'assignment override 3'
      }
    ]

    const props = {discussionTopic: Discussion.mock({})}
    props.discussionTopic.assignment.assignmentOverrides.nodes = overrides
    props.discussionTopic.assignment.dueAt = null
    props.discussionTopic.assignment.unlockAt = null
    props.discussionTopic.assignment.lockAt = null
    const container = setup(props)
    expect(await container.findByText('assignment override 3: Due Apr 5 1:40pm')).toBeTruthy()
  })

  it('Should find no due date text for "assignment override 3"', async () => {
    const overrides = [
      {
        id: 'BXMzaWdebTVubC0x',
        _id: '3',
        dueAt: '',
        lockAt: '2021-09-03T23:59:59-06:00',
        unlockAt: '2021-03-21T00:00:00-06:00',
        title: 'assignment override 3'
      }
    ]

    const props = {discussionTopic: Discussion.mock({})}
    props.discussionTopic.assignment.assignmentOverrides.nodes = overrides
    props.discussionTopic.assignment.dueAt = null
    props.discussionTopic.assignment.unlockAt = null
    props.discussionTopic.assignment.lockAt = null
    const container = setup(props)
    expect(await container.findByText('assignment override 3: No Due Date')).toBeTruthy()
  })

  it('Renders an alert if initialPostRequiredForCurrentUser is true', () => {
    const props = {discussionTopic: Discussion.mock({initialPostRequiredForCurrentUser: true})}
    const container = setup(props)
    expect(container.getByText('You must post before seeing replies.')).toBeInTheDocument()
  })
})
