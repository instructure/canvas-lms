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

import mockGraphqlQuery from '@canvas/graphql-query-mock'
import {INTERNAL_SETTINGS_QUERY} from '../graphql/Queries'
import type {InternalSettingsData} from '../types'
import React from 'react'
import {InternalSettingsView} from '../InternalSettingsView'
import {render} from '@testing-library/react'
import {createCache} from '@canvas/apollo-v3'
import {MockedProvider} from '@apollo/client/testing'
// @ts-expect-error
import type {ExecutionResult} from '@apollo/client'

const mockInternalSettingsQuery = async () => {
  const queryResult = await mockGraphqlQuery(INTERNAL_SETTINGS_QUERY)

  return [
    {
      request: {
        query: INTERNAL_SETTINGS_QUERY,
      },
      result: queryResult as ExecutionResult<InternalSettingsData>,
    },
  ]
}

describe('InternalSettingsView', () => {
  it('renders a list of settings', async () => {
    const internalSettingMocks = await mockInternalSettingsQuery()

    const {findAllByText} = render(
      <MockedProvider mocks={internalSettingMocks} cache={createCache()}>
        <InternalSettingsView />
      </MockedProvider>,
    )

    // graphql-tools mocks most strings as "Hello World", so we have to use findAll
    const elementArrays = await Promise.all(
      // @ts-expect-error
      internalSettingMocks[0].result.data!.internalSettings.flatMap(internalSetting => [
        findAllByText(internalSetting.name),
        internalSetting.secret ? [] : findAllByText(internalSetting.value!),
      ]),
    )

    // @ts-expect-error
    elementArrays.flat().forEach(el => expect(el).toBeInTheDocument())
  })
})
