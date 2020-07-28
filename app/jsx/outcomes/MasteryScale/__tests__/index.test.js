/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

import React from 'react'
import {render, cleanup, wait, fireEvent} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import moxios from 'moxios'
import {OUTCOME_PROFICIENCY_QUERY} from '../api'
import MasteryScale from '../index'

describe('MasteryScale', () => {
  afterEach(cleanup)

  const mocks = [
    {
      request: {
        query: OUTCOME_PROFICIENCY_QUERY,
        variables: {
          contextId: '11'
        }
      },
      result: {
        data: {
          account: {
            __typename: 'Account',
            outcomeCalculationMethod: null,
            outcomeProficiency: {
              __typename: 'OutcomeProficiency',
              _id: '1',
              contextId: 1,
              contextType: 'Account',
              locked: false,
              proficiencyRatingsConnection: {
                __typename: 'ProficiencyRatingConnection',
                nodes: [
                  {
                    __typename: 'ProficiencyRating',
                    _id: '2',
                    color: '009606',
                    description: 'Rating A',
                    mastery: false,
                    points: 9
                  },
                  {
                    __typename: 'ProficiencyRating',
                    _id: '6',
                    color: 'EF4437',
                    description: 'Rating B',
                    mastery: false,
                    points: 6
                  }
                ]
              }
            }
          }
        }
      }
    }
  ]

  it('loads proficiency data', async () => {
    const {getByText, getByDisplayValue} = render(
      <MockedProvider mocks={mocks}>
        <MasteryScale contextType="Account" contextId="11" />
      </MockedProvider>
    )
    expect(getByText('Loading')).not.toEqual(null)
    await wait()
    expect(getByDisplayValue(/Rating A/)).not.toEqual(null)
  })

  it('displays an error on failed request', async () => {
    const {getByText} = render(
      <MockedProvider mocks={[]}>
        <MasteryScale contextType="Account" contextId="11" />
      </MockedProvider>
    )
    await wait()
    expect(getByText(/An error occurred/)).not.toEqual(null)
  })

  describe('update outcomeProficiency', () => {
    beforeEach(() => moxios.install())
    afterEach(() => moxios.uninstall())
    it('submits a request when ratings are updated', async done => {
      const {findByText} = render(
        <MockedProvider mocks={mocks}>
          <MasteryScale contextType="Account" contextId="11" />
        </MockedProvider>
      )
      const button = await findByText('Save Learning Mastery')
      fireEvent.click(button)

      moxios.wait(() => {
        const request = moxios.requests.mostRecent()
        expect(request.config.url).toEqual('/api/v1/accounts/11/outcome_proficiency')
        done()
      })
    })
  })
})
