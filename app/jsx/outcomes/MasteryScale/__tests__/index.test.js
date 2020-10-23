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
import {render, wait, fireEvent} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import moxios from 'moxios'
import {ACCOUNT_OUTCOME_PROFICIENCY_QUERY, COURSE_OUTCOME_PROFICIENCY_QUERY} from '../api'
import MasteryScale from '../index'

describe('MasteryScale', () => {
  beforeEach(() => {
    window.ENV = {
      PROFICIENCY_SCALES_ENABLED_ROLES: [
        {id: '1', role: 'AccountAdmin', label: 'Account Admin', base_role_type: 'AccountMembership'}
      ],
      PERMISSIONS: {
        manage_proficiency_scales: true
      }
    }
  })

  afterEach(() => {
    window.ENV = null
  })

  const outcomeProficiency = {
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

  const mocks = [
    {
      request: {
        query: ACCOUNT_OUTCOME_PROFICIENCY_QUERY,
        variables: {
          contextId: '11'
        }
      },
      result: {
        data: {
          context: {
            __typename: 'Account',
            outcomeProficiency
          }
        }
      }
    },
    {
      request: {
        query: COURSE_OUTCOME_PROFICIENCY_QUERY,
        variables: {
          contextId: '12'
        }
      },
      result: {
        data: {
          context: {
            __typename: 'Course',
            outcomeProficiency
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

  it('loads proficiency data to Course', async () => {
    const {getByText, getByDisplayValue} = render(
      <MockedProvider mocks={mocks}>
        <MasteryScale contextType="Course" contextId="12" />
      </MockedProvider>
    )
    expect(getByText('Loading')).not.toEqual(null)
    await wait()
    expect(getByDisplayValue(/Rating A/)).not.toEqual(null)
  })

  it('loads role list', async () => {
    const {getByText} = render(
      <MockedProvider mocks={mocks}>
        <MasteryScale contextType="Account" contextId="11" />
      </MockedProvider>
    )
    expect(getByText('Loading')).not.toEqual(null)
    await wait()
    expect(getByText(/Permission to change this mastery scale/)).not.toEqual(null)
    expect(getByText(/Account Admin/)).not.toEqual(null)
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

  it('loads default data when request returns no ratings/method', async () => {
    const emptyMocks = [
      {
        request: {
          query: ACCOUNT_OUTCOME_PROFICIENCY_QUERY,
          variables: {
            contextId: '11'
          }
        },
        result: {
          data: {
            context: {
              __typename: 'Account',
              outcomeProficiency: null
            }
          }
        }
      }
    ]
    const {getByText} = render(
      <MockedProvider mocks={emptyMocks}>
        <MasteryScale contextType="Account" contextId="11" />
      </MockedProvider>
    )
    await wait()
    expect(getByText('Mastery')).not.toBeNull()
  })

  describe('update outcomeProficiency', () => {
    beforeEach(() => {
      moxios.install()
    })
    afterEach(() => {
      moxios.uninstall()
    })

    it('submits a request when ratings are saved', async () => {
      const {findAllByLabelText, getByText} = render(
        <MockedProvider mocks={mocks}>
          <MasteryScale contextType="Account" contextId="11" />
        </MockedProvider>
      )
      const pointsInput = (await findAllByLabelText(/Change points/))[0]
      fireEvent.change(pointsInput, {target: {value: '100'}})
      fireEvent.click(getByText('Save Mastery Scale'))
      fireEvent.click(getByText('Save'))

      await wait(() => {
        const request = moxios.requests.mostRecent()
        expect(request).not.toBeUndefined()
        expect(request.config.url).toEqual('/api/v1/accounts/11/outcome_proficiency')
      })
    })
  })

  describe('can not manage', () => {
    beforeEach(() => {
      window.ENV.PERMISSIONS = {
        manage_proficiency_scales: false
      }
    })

    afterEach(() => {
      window.ENV.PERMISSIONS = null
    })

    it('hides role list', async () => {
      const {getByText, queryByText} = render(
        <MockedProvider mocks={mocks}>
          <MasteryScale contextType="Account" contextId="11" />
        </MockedProvider>
      )
      expect(getByText('Loading')).not.toEqual(null)
      await wait()
      expect(queryByText(/Permission to change this mastery calculation/)).not.toBeInTheDocument()
      expect(queryByText(/Account Admin/)).not.toBeInTheDocument()
    })
  })
})
