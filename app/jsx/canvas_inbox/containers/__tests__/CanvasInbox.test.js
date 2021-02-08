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

import {AlertManagerContext} from '../../../shared/components/AlertManager'
import CanvasInbox from '../CanvasInbox'
import {createCache} from '../../../canvas-apollo'
import {CONVERSATIONS_QUERY} from '../../Queries'
import {MockedProvider} from '@apollo/react-testing'
import React from 'react'
import {render} from '@testing-library/react'
import {mockQuery} from '../../mocks'
import waitForApolloLoading from '../../helpers/waitForApolloLoading'

const createGraphqlMocks = () => {
  const mocks = [
    {
      request: {
        query: CONVERSATIONS_QUERY,
        variables: {
          userID: '1',
          scope: 'inbox'
        },
        overrides: {
          Node: {
            __typename: 'User'
          }
        }
      }
    }
  ]

  const mockResults = Promise.all(
    mocks.map(async m => {
      const result = await mockQuery(m.request.query, m.request.overrides, m.request.variables)
      return {
        request: {query: m.request.query, variables: m.request.variables},
        result
      }
    })
  )
  return mockResults
}

const setup = async () => {
  const mocks = await createGraphqlMocks()
  return render(
    <AlertManagerContext.Provider value={{setOnFailure: jest.fn(), setOnSuccess: jest.fn()}}>
      <MockedProvider mocks={mocks} cache={createCache()}>
        <CanvasInbox />
      </MockedProvider>
    </AlertManagerContext.Provider>
  )
}

describe('CanvasInbox App Container', () => {
  beforeEach(() => {
    window.ENV = {
      current_user_id: 1
    }
  })

  describe('rendering', () => {
    it('should render <CanvasInbox />', async () => {
      const component = await setup()

      await waitForApolloLoading()

      expect(await component).toBeTruthy()
    })
  })
})
