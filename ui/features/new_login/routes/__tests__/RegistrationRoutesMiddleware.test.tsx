/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import React from 'react'
import {MemoryRouter} from 'react-router-dom'
import {NewLoginDataProvider} from '../../context'
import RegistrationRoutesMiddleware from '../RegistrationRoutesMiddleware'

jest.mock('../../context/NewLoginDataContext', () => {
  const actualContext = jest.requireActual('../../context/NewLoginDataContext')
  return {
    ...actualContext,
    useNewLoginData: () => ({
      ...actualContext.useNewLoginData(),
      // mock the data attribute default values that would normally be provided by the back-end
      selfRegistrationType: 'all',
    }),
  }
})

describe('RegistrationRoutesMiddleware', () => {
  it('mounts without crashing', () => {
    render(
      <MemoryRouter initialEntries={['/login/canvas/register/landing']}>
        <NewLoginDataProvider>
          <RegistrationRoutesMiddleware />
        </NewLoginDataProvider>
      </MemoryRouter>,
    )
  })
})
