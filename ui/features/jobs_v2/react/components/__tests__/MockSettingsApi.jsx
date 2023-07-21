/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import {render} from '@testing-library/react'
import {MockedProvider} from '@apollo/react-testing'
import {GET_SETTING_QUERY, SET_SETTING_MUTATION} from '../../../graphql/Queries'

const settingsMocks = [
  {
    request: {
      query: GET_SETTING_QUERY,
      variables: {name: 'foobar_num_strands'},
    },
    result: {
      data: {
        internalSetting: {
          id: 'SW50ZXJuYWxTZXR0aW5nLTE3',
          value: '10',
          __typename: 'InternalSetting',
        },
      },
    },
  },
  {
    request: {
      query: SET_SETTING_MUTATION,
      variables: {
        id: 'SW50ZXJuYWxTZXR0aW5nLTE3',
        value: '14',
      },
    },
    result: jest.fn(() => {
      return {
        data: {
          updateInternalSetting: {
            internalSetting: {
              id: 'SW50ZXJuYWxTZXR0aW5nLTE3',
              value: '14',
              __typename: 'InternalSetting',
            },
            errors: null,
            __typename: 'UpdateInternalSettingPayload',
          },
        },
      }
    }),
  },
]

export default function renderWithMocks(element) {
  return render(<MockedProvider mocks={settingsMocks}>{element}</MockedProvider>)
}

export const updateInternalSettingMutation = settingsMocks[1].result
