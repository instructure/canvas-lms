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
import {render as rtlRender, waitFor, fireEvent} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import moxios from 'moxios'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'
import {ACCOUNT_OUTCOME_PROFICIENCY_QUERY} from '@canvas/outcomes/graphql/MasteryScale'
import MasteryScale from '../index'
import {masteryScalesGraphqlMocks} from '@canvas/outcomes/mocks/Outcomes'

jest.useFakeTimers()

describe('MasteryScale', () => {
  beforeEach(() => {
    window.ENV = {
      PROFICIENCY_SCALES_ENABLED_ROLES: [
        {
          id: '1',
          role: 'AccountAdmin',
          label: 'Account Admin',
          base_role_type: 'AccountMembership',
          is_account_role: true,
        },
        {
          id: '2',
          role: 'TeacherEnrollment',
          label: 'Teacher',
          base_role_type: 'TeacherEnrollment',
          is_account_role: false,
        },
      ],
      PERMISSIONS: {
        manage_proficiency_scales: true,
      },
    }
  })

  afterEach(() => {
    window.ENV = null
  })

  const render = (
    children,
    {contextType = 'Account', contextId = '11', mocks = masteryScalesGraphqlMocks} = {}
  ) => {
    return rtlRender(
      <OutcomesContext.Provider value={{env: {contextType, contextId}}}>
        <MockedProvider mocks={mocks}>{children}</MockedProvider>
      </OutcomesContext.Provider>
    )
  }

  it('loads proficiency data', async () => {
    const {getByText, getByDisplayValue} = render(<MasteryScale />)
    expect(getByText('Loading')).toBeInTheDocument()
    await waitFor(() => expect(getByDisplayValue(/Rating A/)).toBeInTheDocument())
  })

  it('loads proficiency data to Course', async () => {
    const {getByText, getByDisplayValue} = render(
      <MasteryScale contextType="Course" contextId="12" />,
      {contextType: 'Course', contextId: '12'}
    )
    expect(getByText('Loading')).toBeInTheDocument()
    await waitFor(() => expect(getByDisplayValue(/Rating A/)).toBeInTheDocument())
  })

  it('loads role list', async () => {
    const {getByText, getAllByText} = render(<MasteryScale />)
    expect(getByText('Loading')).toBeInTheDocument()
    await waitFor(() => {
      expect(
        getByText(/Permission to change this mastery scale at the account level is enabled for/)
      ).toBeInTheDocument()
      expect(
        getByText(/Permission to change this mastery scale at the course level is enabled for/)
      ).toBeInTheDocument()
      expect(getAllByText(/Account Admin/).length).not.toBe(0)
      expect(getByText(/Teacher/)).toBeInTheDocument()
    })
  })

  it('displays an error on failed request', async () => {
    const {getByText} = render(<MasteryScale />, {mocks: []})
    await waitFor(() => expect(getByText(/An error occurred/)).toBeInTheDocument())
  })

  it('loads default data when request returns no ratings/method', async () => {
    const emptyMocks = [
      {
        request: {
          query: ACCOUNT_OUTCOME_PROFICIENCY_QUERY,
          variables: {
            contextId: '11',
          },
        },
        result: {
          data: {
            context: {
              __typename: 'Account',
              outcomeProficiency: null,
            },
          },
        },
      },
    ]
    const {getByText} = render(<MasteryScale />, {mocks: emptyMocks})
    await waitFor(() => expect(getByText('Mastery')).not.toBeNull())
  })

  describe('update outcomeProficiency', () => {
    beforeEach(() => {
      moxios.install()
    })
    afterEach(() => {
      moxios.uninstall()
    })

    it('submits a request when ratings are saved', async () => {
      const {findAllByLabelText, getByText} = render(<MasteryScale />)
      const pointsInput = (await findAllByLabelText(/Change points/))[0]
      fireEvent.change(pointsInput, {target: {value: '100'}})
      fireEvent.click(getByText('Save Mastery Scale'))
      fireEvent.click(getByText('Save'))

      await waitFor(() => {
        const request = moxios.requests.mostRecent()
        expect(request).not.toBeUndefined()
        expect(request.config.url).toEqual('/api/v1/accounts/11/outcome_proficiency')
      })
    })
  })

  describe('can not manage', () => {
    beforeEach(() => {
      window.ENV.PERMISSIONS = {
        manage_proficiency_scales: false,
      }
    })

    afterEach(() => {
      window.ENV.PERMISSIONS = null
    })

    it('hides mastery info', async () => {
      const {getByText, queryByText} = render(<MasteryScale />)
      expect(getByText('Loading')).toBeInTheDocument()
      await waitFor(() =>
        expect(
          queryByText(
            /This mastery scale will be used as the default for all courses within your account/
          )
        ).not.toBeInTheDocument()
      )
    })
  })
})
