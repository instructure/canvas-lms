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
    />,
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
