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

import {MockedProvider} from '@apollo/react-testing'
import {AlertManagerContext} from '@canvas/alerts/react/AlertManager'
import {render} from '@testing-library/react'
import React from 'react'
import CoursePeople from '../CoursePeople'
import {getRosterQueryMock} from '../../../graphql/Mocks'

describe('CoursePeople', () => {
  const setOnFailure = jest.fn()
  const setOnSuccess = jest.fn()

  const setup = mocks => {
    return render(
      <MockedProvider mocks={mocks} addTypename={false}>
        <AlertManagerContext.Provider value={{setOnFailure, setOnSuccess}}>
          <CoursePeople />
        </AlertManagerContext.Provider>
      </MockedProvider>
    )
  }

  beforeAll(() => {
    window.ENV = {
      course: {id: '1'}
    }
  })

  it('should render', () => {
    const container = setup(getRosterQueryMock())
    expect(container).toBeTruthy()
  })
})
