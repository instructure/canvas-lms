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

import {DueDateTray} from '../DueDateTray'

import React from 'react'

import {render} from '@testing-library/react'

import {responsiveQuerySizes} from '../../../utils'

jest.mock('../../../utils')

beforeAll(() => {
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

const overrides = [
  {
    id: 'QXNzaWdebTVubC0x',
    _id: '1',
    dueAt: '2021-03-30T23:59:59-06:00',
    lockAt: '2021-04-03T23:59:59-06:00',
    unlockAt: '2021-03-24T00:00:00-06:00',
    title: 'assignment override 1'
  },
  {
    id: 'QXMzaWdebTubeC0x',
    _id: '2',
    dueAt: '2021-03-27T23:59:59-06:00',
    lockAt: '2021-04-07T23:59:59-06:00',
    unlockAt: '2021-03-21T00:00:00-06:00',
    title: 'assignment override 2'
  },
  {
    id: 'BXMzaWdebTVubC0x',
    _id: '3',
    dueAt: '2021-05-27T23:59:59-06:00',
    lockAt: '2021-09-03T23:59:59-06:00',
    unlockAt: '2021-03-21T00:00:00-06:00',
    title: 'assignment override 3'
  }
]

const setup = props => {
  return render(<DueDateTray assignmentOverrides={overrides} {...props} />)
}

describe('AssignmentDetails', () => {
  describe('desktop', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        desktop: {maxWidth: '1000px'}
      }))
    })

    it('displays tray and correctly formatted dates', async () => {
      const {findByText} = setup()
      expect(await findByText('Due Dates')).toBeTruthy()
      expect(await findByText('Mar 31 5:59am')).toBeTruthy()
      expect(await findByText('assignment override 1')).toBeTruthy()
      expect(await findByText('Mar 24 6am')).toBeTruthy()
      expect(await findByText('Apr 4 5:59am')).toBeTruthy()
    })

    it('correct text is shown when a date is not set', async () => {
      const nullOverrides = overrides
      nullOverrides[2].dueAt = null
      nullOverrides[2].unlockAt = null
      nullOverrides[2].lockAt = null
      const {findByText} = setup({assignmentOverrides: nullOverrides})
      expect(await findByText('No Due Date')).toBeTruthy()
      expect(await findByText('No Start Date')).toBeTruthy()
      expect(await findByText('No End Date')).toBeTruthy()
    })
  })

  describe('mobile', () => {
    beforeEach(() => {
      responsiveQuerySizes.mockImplementation(() => ({
        mobile: {maxWidth: '1000px'}
      }))
    })

    it('displays tray and correctly formatted dates', async () => {
      const {findByText} = setup()
      expect(await findByText('Mar 31 5:59am')).toBeTruthy()
      expect(await findByText('assignment override 1')).toBeTruthy()
      expect(await findByText('Mar 24 6am')).toBeTruthy()
      expect(await findByText('Apr 4 5:59am')).toBeTruthy()
    })

    it('correct text is shown when a date is not set', async () => {
      const nullOverrides = overrides
      nullOverrides[2].dueAt = null
      nullOverrides[2].unlockAt = null
      nullOverrides[2].lockAt = null
      const {findByText} = setup({assignmentOverrides: nullOverrides})
      expect(await findByText('No Due Date')).toBeTruthy()
      expect(await findByText('No Start Date')).toBeTruthy()
      expect(await findByText('No End Date')).toBeTruthy()
    })
  })
})
