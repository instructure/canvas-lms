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
import {Assignment} from '../../../../graphql/Assignment'
import {Discussion} from '../../../../graphql/Discussion'
import {DiscussionPermissions} from '../../../../graphql/DiscussionPermissions'
import {DiscussionTopicContainer} from '../DiscussionTopicContainer'
import {fireEvent, render} from '@testing-library/react'
import {
  getEditUrl,
  getSpeedGraderUrl,
  getPeerReviewsUrl,
  responsiveQuerySizes
} from '../../../utils'
import {handlers} from '../../../../graphql/mswHandlers'
import {mswClient} from '../../../../../../shared/msw/mswClient'
import {mswServer} from '../../../../../../shared/msw/mswServer'
import {PeerReviews} from '../../../../graphql/PeerReviews'
import React from 'react'
import {waitFor} from '@testing-library/dom'

jest.mock('@canvas/rce/RichContentEditor')
jest.mock('../../../utils', () => ({
  ...jest.requireActual('../../../utils'),
  responsiveQuerySizes: jest.fn()
}))

describe('DiscussionTopicContainer', () => {
  const server = mswServer(handlers)
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()
  const assignMock = jest.fn()
  const openMock = jest.fn()
  let liveRegion = null

  beforeAll(() => {
    delete window.location
    window.location = {assign: assignMock}
    window.open = openMock
    window.ENV = {
      context_asset_string: 'course_1',
      course_id: '1',
      discussion_topic_menu_tools: [
        {
          base_url: 'example.com',
          canvas_icon_class: 'icon-commons',
          id: '1',
          title: 'Share to Commons'
        }
      ]
    }

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn()
      }
    })

    if (!document.getElementById('flash_screenreader_holder')) {
      liveRegion = document.createElement('div')
      liveRegion.id = 'flash_screenreader_holder'
      liveRegion.setAttribute('role', 'alert')
      document.body.appendChild(liveRegion)
    }

    window.INST = {
      editorButtons: []
    }

    // eslint-disable-next-line no-undef
    fetchMock.dontMock()
    server.listen()

    window.matchMedia = jest.fn().mockImplementation(() => {
      return {
        matches: true,
        media: '',
        onchange: null,
        addListener: jest.fn(),
        removeListener: jest.fn()
      }
    })
  })

  beforeEach(() => {
    responsiveQuerySizes.mockImplementation(() => ({
      desktop: {maxWidth: '1000px'}
    }))
  })

  afterEach(() => {
    setOnFailure.mockClear()
    setOnSuccess.mockClear()
    assignMock.mockClear()
    openMock.mockClear()
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
    const {getByText} = setup({discussionTopic: Discussion.mock({canUnpublish: false})})

    expect(getByText('Published').closest('button').hasAttribute('disabled')).toBeTruthy()
  })

  it('renders a special alert for differentiated group assignments for readAsAdmin', async () => {
    const container = setup({
      discussionTopic: Discussion.mock({
        assignment: Assignment.mock({onlyVisibleToOverrides: true})
      })
    })
    expect(
      container.getByText(
        'Note: for differentiated group topics, some threads may not have any students assigned.'
      )
    ).toBeInTheDocument()
  })

  it('non-readAsAdmin does not see Diff. Group Assignments alert', async () => {
    const container = setup({
      discussionTopic: Discussion.mock({
        assignment: Assignment.mock({onlyVisibleToOverrides: true}),
        permissions: DiscussionPermissions.mock({readAsAdmin: false})
      })
    })
    expect(await container.findByTestId('graded-discussion-info')).toBeTruthy()
    expect(container.queryByTestId('differentiated-alert')).toBeFalsy()
  })

  it('renders without optional props', async () => {
    const container = setup({discussionTopic: Discussion.mock({assignment: {}})})
    expect(container.getByTestId('replies-counter')).toBeInTheDocument()
    expect(container.getByText('No Due Date')).toBeInTheDocument()
    expect(container.getByText('0 points possible')).toBeInTheDocument()
  })

  it('renders infoText only when there are replies', async () => {
    const container = setup({discussionTopic: Discussion.mock()})
    const infoText = await container.findByTestId('replies-counter')
    expect(infoText).toHaveTextContent('56 replies, 2 unread')
  })

  it('does not render unread when there are none', async () => {
    const container = setup({
      discussionTopic: Discussion.mock({
        entryCounts: {
          repliesCount: 24,
          unreadCount: 0
        }
      })
    })
    const infoText = await container.findByTestId('replies-counter')
    expect(infoText).toHaveTextContent('24 replies')
  })

  it('renders Graded info when assignment info exists', async () => {
    const container = setup({
      discussionTopic: Discussion.mock({
        assignment: Assignment.mock({pointsPossible: 5, assignmentOverrides: null})
      })
    })
    const gradedDiscussionInfo = await container.findByTestId('graded-discussion-info')
    expect(gradedDiscussionInfo).toHaveTextContent('5 points possible')
  })

  it('should be able to send to edit page when canUpdate', async () => {
    const {getByTestId, getByText} = setup({discussionTopic: Discussion.mock()})
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Edit'))

    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith(getEditUrl('1', '1'))
    })
  })

  it('should be able to send to peer reviews page when canPeerReview', async () => {
    const {getByTestId, getByText} = setup({discussionTopic: Discussion.mock()})
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Peer Reviews'))

    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith(getPeerReviewsUrl('1', '1'))
    })
  })

  it('Should be able to delete topic', async () => {
    window.confirm = jest.fn(() => true)
    const {getByTestId, getByText} = setup({discussionTopic: Discussion.mock()})
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
      discussionTopic: Discussion.mock({permissions: DiscussionPermissions.mock({delete: false})})
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(queryByTestId('delete')).toBeNull()
  })

  it('Should be able to open SpeedGrader', async () => {
    const {getByTestId, getByText} = setup({discussionTopic: Discussion.mock()})
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Open in Speedgrader'))

    await waitFor(() => {
      expect(openMock).toHaveBeenCalledWith(getSpeedGraderUrl('1', '1'), '_blank')
    })
  })

  it('Should find due date text for assignment', async () => {
    const container = setup({
      discussionTopic: Discussion.mock({
        permissions: DiscussionPermissions.mock({readAsAdmin: false})
      })
    })
    expect(await container.findByText('Due: Mar 31 5:59am')).toBeTruthy()
  })

  it('Should not be able to see post menu if no permissions and initialPostRequiredForCurrentUser', () => {
    const {queryByTestId} = setup({
      discussionTopic: Discussion.mock({
        initialPostRequiredForCurrentUser: true,
        permissions: DiscussionPermissions.mock({
          canDelete: false,
          copyAndSendTo: false,
          update: false,
          moderateForum: false,
          speedGrader: false,
          peerReview: false,
          showRubric: false,
          addRubric: false,
          openForComments: false,
          closeForComments: false,
          manageContent: false
        })
      })
    })

    expect(queryByTestId('discussion-post-menu-trigger')).toBeNull()
  })

  it('Should show Mark All as Read discussion topic menu if initialPostRequiredForCurrentUser = false', async () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: Discussion.mock({initialPostRequiredForCurrentUser: false})
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Mark All as Read')).toBeInTheDocument()
  })

  it('Should show Mark All as Unread discussion topic menu if initialPostRequiredForCurrentUser = false', async () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: Discussion.mock({initialPostRequiredForCurrentUser: false})
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Mark All as Unread')).toBeInTheDocument()
  })

  it('Should be able to click Mark All as Read and call mutation', async () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: Discussion.mock({initialPostRequiredForCurrentUser: false})
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Mark All as Read'))

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('You have successfully marked all as read.')
    )
  })

  it('Should be able to click Mark All as Unread and call mutation', async () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: Discussion.mock({initialPostRequiredForCurrentUser: false})
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Mark All as Unread'))

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith('You have successfully marked all as unread.')
    )
  })

  it('Renders Add Rubric in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({discussionTopic: Discussion.mock()})
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Add Rubric')).toBeInTheDocument()
  })

  it('Renders Show Rubric in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: Discussion.mock({
        permissions: DiscussionPermissions.mock({
          addRubric: false
        })
      })
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Show Rubric')).toBeInTheDocument()
  })

  it('Renders Open for Comments in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({discussionTopic: Discussion.mock()})
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Open for Comments')).toBeInTheDocument()
  })

  it('Renders Close for Comments in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({
      discussionTopic: Discussion.mock({
        rootTopic: null,
        permissions: DiscussionPermissions.mock({closeForComments: true})
      })
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Close for Comments')).toBeInTheDocument()
  })

  it('does not render Close for Comments even when there is permission if child topic', () => {
    const container = setup({
      discussionTopic: Discussion.mock({
        permissions: DiscussionPermissions.mock({closeForComments: true})
      })
    })
    fireEvent.click(container.getByTestId('discussion-post-menu-trigger'))
    expect(container.queryByText('Close for Comments')).toBeNull()
  })

  it('Renders Copy To and Send To in the kabob menu if the user has permission', () => {
    const {getByTestId, getByText} = setup({discussionTopic: Discussion.mock()})

    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    expect(getByText('Copy To...')).toBeInTheDocument()
    expect(getByText('Send To...')).toBeInTheDocument()
  })

  it('renders a modal to send content', async () => {
    const container = setup({discussionTopic: Discussion.mock()})
    const kebob = await container.findByTestId('discussion-post-menu-trigger')
    fireEvent.click(kebob)

    const sendToButton = await container.findByText('Send To...')
    fireEvent.click(sendToButton)
    expect(await container.findByText('Send to:')).toBeTruthy()
  })

  // eslint-disable-next-line jest/no-disabled-tests
  it.skip('renders a modal to copy content', async () => {
    const container = setup({discussionTopic: Discussion.mock()})
    const kebob = await container.findByTestId('discussion-post-menu-trigger')
    fireEvent.click(kebob)
    const copyToButton = await container.findByText('Copy To...')
    fireEvent.click(copyToButton)
    expect(await container.findByText('Select a Course')).toBeTruthy()
  })

  it('can send users to Commons if they can manageContent', async () => {
    const discussionTopic = Discussion.mock()
    const {getByTestId, getByText} = setup({discussionTopic})
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Share to Commons'))

    await waitFor(() => {
      expect(assignMock).toHaveBeenCalledWith(
        `example.com&discussion_topics%5B%5D=${discussionTopic._id}`
      )
    })
  })

  it('renders an attachment if it exists', async () => {
    const container = setup({discussionTopic: Discussion.mock()})
    expect(await container.findByText('288777.jpeg')).toBeInTheDocument()
  })

  it('renders a reply button if user has reply permission true', async () => {
    const container = setup({discussionTopic: Discussion.mock()})

    expect(await container.findByText('This is a Discussion Topic Message')).toBeInTheDocument()
    expect(await container.findByTestId('discussion-topic-reply')).toBeInTheDocument()
  })

  it('does not render a reply button if user has reply permission false', () => {
    const container = setup({
      discussionTopic: Discussion.mock({permissions: DiscussionPermissions.mock({reply: false})})
    })

    expect(container.queryByTestId('discussion-topic-reply')).toBeNull()
  })

  it('should not render group menu button when there is child topics but no group set', () => {
    const container = setup({discussionTopic: Discussion.mock({groupSet: null})})

    expect(container.queryByTestId('groups-menu-btn')).toBeFalsy()
  })

  it('Should be able to close for comments', async () => {
    const {getByText, getByTestId} = setup({
      discussionTopic: Discussion.mock({
        rootTopic: null,
        permissions: DiscussionPermissions.mock({closeForComments: true})
      })
    })
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Close for Comments'))

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith(
        'You have successfully updated the discussion topic.'
      )
    )
  })

  it('Should be able to open for comments', async () => {
    const {getByText, getByTestId} = setup({discussionTopic: Discussion.mock()})
    fireEvent.click(getByTestId('discussion-post-menu-trigger'))
    fireEvent.click(getByText('Open for Comments'))

    await waitFor(() =>
      expect(setOnSuccess).toHaveBeenCalledWith(
        'You have successfully updated the discussion topic.'
      )
    )
  })

  it('Should find due date text', async () => {
    const container = setup({
      discussionTopic: Discussion.mock({assignment: Assignment.mock({assignmentOverrides: null})})
    })
    expect(await container.findByText('Everyone: Due Mar 31 5:59am')).toBeTruthy()
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
    waitFor(() =>
      expect(container.queryByText('You must post before seeing replies.')).toBeInTheDocument()
    )
  })

  it('Renders an alert if announcement will post in the future', () => {
    const farInTheFuture = {
      property: '3000-01-01T13:40:50Z',
      expectedText: 'This announcement will not be visible until Jan 1, 3000 1:40pm.'
    } // change values in this object on the year 3000
    const props = {
      discussionTopic: Discussion.mock({
        isAnnouncement: true,
        delayedPostAt: farInTheFuture.property
      })
    }
    const container = setup(props)
    expect(container.getByText(farInTheFuture.expectedText)).toBeTruthy()
  })

  it('should not render author if author is null', async () => {
    const props = {discussionTopic: Discussion.mock({author: null})}
    const container = setup(props)
    const pillContainer = container.queryAllByTestId('pill-Author')
    expect(pillContainer).toEqual([])
  })

  it('should render editedBy if editor is different from author', async () => {
    const props = {
      discussionTopic: Discussion.mock({
        editor: {
          id: 'vfx5000',
          _id: '99',
          displayName: 'Eddy Tor',
          avatarUrl: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
        }
      })
    }
    const container = setup(props)
    expect(container.getByText(`Edited by Eddy Tor Apr 22 6:41pm`)).toBeInTheDocument()
    expect(container.queryByTestId('created-tooltip')).toBeFalsy()
  })

  it('should render plain edited if author is editor', async () => {
    const props = {
      discussionTopic: Discussion.mock({
        editor: {
          id: 'abc3244',
          _id: '1',
          name: 'Charles Xavier',
          avatarUrl: 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
        }
      })
    }
    const container = setup(props)
    expect(container.getByText(`Edited Apr 22 6:41pm`)).toBeInTheDocument()
    expect(container.queryByTestId('created-tooltip')).toBeFalsy()
  })

  it('should not render edited info if no editor', async () => {
    const props = {
      discussionTopic: Discussion.mock({
        editor: null
      })
    }
    const container = setup(props)
    expect(container.queryByText(/Edited by/)).toBeFalsy()
    expect(container.queryByTestId('created-tooltip')).toBeFalsy()
  })

  describe('Peer Reviews', () => {
    it('renders with a due date', () => {
      const props = {discussionTopic: Discussion.mock()}
      const {getByText} = setup(props)

      expect(getByText('Peer review for Morty Smith Due: Mar 31 5:59am')).toBeTruthy()
    })

    it('renders with out a due date', () => {
      const props = {
        discussionTopic: Discussion.mock({
          assignment: Assignment.mock({
            peerReviews: PeerReviews.mock({dueAt: null})
          })
        })
      }
      const {getByText} = setup(props)

      expect(getByText('Peer review for Morty Smith')).toBeTruthy()
    })

    it('does not render peer reviews if there are not any', () => {
      const props = {
        discussionTopic: Discussion.mock({
          peerReviews: null,
          assessmentRequestsForCurrentUser: []
        })
      }
      const {queryByText} = setup(props)

      expect(queryByText('eer review for Morty Smith Due: Mar 31 5:59am')).toBeNull()
    })
  })
})
