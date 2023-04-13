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

import {DiscussionDetails} from '../DiscussionDetails'
import {Assignment} from '../../../../graphql/Assignment'

import {responsiveQuerySizes} from '../../../utils/index'

import React from 'react'
import {fireEvent, render} from '@testing-library/react'
import {Discussion} from '../../../../graphql/Discussion'
import {DiscussionPermissions} from '../../../../graphql/DiscussionPermissions'

jest.mock('../../../utils')

const mockOverrides = [
  {
    id: 'QXNzaWdebTVubC0x',
    _id: '1',
    dueAt: '2021-03-30T23:59:59-06:00',
    lockAt: '2021-04-03T23:59:59-06:00',
    unlockAt: '2021-03-24T00:00:00-06:00',
    title: 'assignment override 1',
  },
  {
    id: 'QXMzaWdebTubeC0x',
    _id: '2',
    dueAt: '2021-03-27T23:59:59-06:00',
    lockAt: '2021-04-03T23:59:59-06:00',
    unlockAt: '2021-03-21T00:00:00-06:00',
    title: 'assignment override 2',
  },
  {
    id: 'BXMzaWdebTVubC0x',
    _id: '3',
    dueAt: '2021-03-27T23:59:59-06:00',
    lockAt: '2021-09-03T23:59:59-06:00',
    unlockAt: '2021-03-21T00:00:00-06:00',
    title: 'assignment override 3',
  },
]

const mockSections = [
  {
    id: 'U2VjdGlvbi00',
    _id: '1',
    userCount: 5,
    name: 'section 1',
  },
  {
    id: 'U2VjdGlvbi00',
    _id: '2',
    userCount: 99,
    name: 'section 2',
  },
]

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

beforeEach(() => {
  responsiveQuerySizes.mockImplementation(() => ({
    desktop: {maxWidth: '1000px'},
  }))
})

const setup = (props, overrides = [], pointsPossible = 7) => {
  return render(
    <DiscussionDetails
      discussionTopic={Discussion.mock({
        assignment: Assignment.mock({assignmentOverrides: {nodes: overrides}, pointsPossible}),
      })}
      {...props}
    />
  )
}

describe('DiscussionDetails', () => {
  describe('desktop', () => {
    describe('non-graded availability', () => {
      const mockTopic = Discussion.mock({
        courseSections: mockSections,
        userCount: 1,
        lockAt: '2022-01-19T23:59:59-07:00',
        delayedPostAt: '2022-01-12T00:00:00-07:00',
        groupSet: null,
        anonymousState: null,
        assignment: null,
      })
      it('displays "View Availability" button', () => {
        const {getByText} = setup({discussionTopic: mockTopic})
        expect(getByText('View Availability')).toBeTruthy()
      })

      it('displays DiscussionAvailabilityContainer when not graded', () => {
        const {getByTestId} = setup({
          discussionTopic: Discussion.mock({
            courseSections: mockSections,
            userCount: 1,
            assignment: null,
          }),
        })
        expect(getByTestId('non-graded-discussion-info')).toBeTruthy()
      })
    })
    describe('graded assignments', () => {
      it('displays points possible info', () => {
        const {queryByText} = setup()
        expect(queryByText('7 points possible')).toBeTruthy()
      })

      it('displays correct pluralization', () => {
        const {queryByText} = setup({}, [], 1)
        expect(queryByText('1 point possible')).toBeTruthy()
      })

      it('displays points possible with 2 decimal places', () => {
        const {queryByText} = setup({}, [], 4.333)
        expect(queryByText('4.33 points possible')).toBeTruthy()
      })

      it('displays due date when there are no overrides', () => {
        const {queryByText} = setup()
        expect(queryByText('Everyone')).toBeTruthy()
        expect(queryByText('Due Mar 31, 2021 5:59am')).toBeTruthy()
        expect(queryByText('Available from Mar 24, 2021 until Apr 4, 2021')).toBeTruthy()
      })

      it('displays "Show due dates" button when there are overrides', () => {
        const {getByText} = setup({}, mockOverrides)
        expect(getByText('Show Due Dates (4)')).toBeTruthy()
      })

      it('displays tray and correctly formatted dates', async () => {
        const {queryByText, findByText, findAllByTestId} = setup({}, mockOverrides)
        expect(queryByText('Show Due Dates (4)')).toBeTruthy()
        fireEvent.click(queryByText('Show Due Dates (4)'))
        expect(await findAllByTestId('assignment-override-row')).toBeTruthy()
        expect(await findByText('Sep 4, 2021 5:59am')).toBeTruthy()
      })

      it('correct text is shown when a date is not set', async () => {
        mockOverrides[2].dueAt = null
        mockOverrides[2].unlockAt = null
        mockOverrides[2].lockAt = null
        const {queryByText, findByText} = setup({}, mockOverrides)
        expect(queryByText('Show Due Dates (4)')).toBeTruthy()
        fireEvent.click(queryByText('Show Due Dates (4)'))
        expect(await findByText('No Due Date')).toBeTruthy()
        expect(await findByText('No Start Date')).toBeTruthy()
        expect(await findByText('No End Date')).toBeTruthy()
      })
    })
  })

  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        tablet: {maxWidth: '767px'},
      }))
    })
    describe('non-graded availability', () => {
      const mockTopic = Discussion.mock({
        courseSections: mockSections,
        userCount: 1,
        lockAt: '2022-01-19T23:59:59-07:00',
        delayedPostAt: '2022-01-12T00:00:00-07:00',
        groupSet: null,
        anonymousState: null,
        assignment: null,
      })
      it('displays "View Availability" button', () => {
        const {getByText} = setup({discussionTopic: mockTopic})
        expect(getByText('View Availability')).toBeTruthy()
      })

      it('displays DiscussionAvailabilityContainer when not graded', () => {
        const {getByTestId} = setup({discussionTopic: mockTopic})
        expect(getByTestId('non-graded-discussion-info')).toBeTruthy()
      })
    })

    describe('graded assignments', () => {
      it('displays points possible info', () => {
        const {queryByText} = setup()
        expect(queryByText('7 points')).toBeTruthy()
      })

      it('displays correct pluralization', () => {
        const {queryByText} = setup({}, [], 1)
        expect(queryByText('1 point')).toBeTruthy()
      })

      it('displays points possible with 2 decimal places', () => {
        const {queryByText} = setup({}, [], 4.333333)
        expect(queryByText('4.33 points')).toBeTruthy()
      })

      it('displays "Show due dates" button when there are overrides', () => {
        const {queryByText} = setup({}, mockOverrides)
        expect(queryByText('Due Dates (4)')).toBeTruthy()
      })
      describe('Restrict Quantitative Data is true', () => {
        const mockTopic = Discussion.mock({
          courseSections: mockSections,
          userCount: 1,
          groupSet: null,
          anonymousState: null,
          assignment: Assignment.mock({pointsPossible: 7, restrictQuantitativeData: true}),
          permissions: DiscussionPermissions.mock({readAsAdmin: false}),
        })

        it('does not displays points possible when RQD is true', () => {
          const {queryByText} = setup({discussionTopic: mockTopic})
          expect(queryByText('7 points')).toBeFalsy()
        })
      })
    })
  })
})
