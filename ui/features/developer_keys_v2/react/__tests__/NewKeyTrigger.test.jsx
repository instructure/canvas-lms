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
import {render, screen} from '@testing-library/react'
import DeveloperKeyModalTrigger from '../NewKeyTrigger'
import userEvent from '@testing-library/user-event'

const store = {
  dispatch: () => {},
}

const actions = {
  developerKeysModalOpen: jest.fn(),
  ltiKeysSetLtiKey: jest.fn(),
}

const renderDeveloperKeyModalTrigger = () =>
  render(<DeveloperKeyModalTrigger store={store} actions={actions} setAddKeyButtonRef={() => {}} />)

describe('DeveloperKeyModalTrigger', () => {
  beforeEach(async () => {
    window.ENV = {
      FEATURES: {
        lti_dynamic_registration: true,
      },
    }
    renderDeveloperKeyModalTrigger()

    await userEvent.click(
      screen.getByRole('button', {
        name: /create a developer key/i,
      })
    )
  })

  afterEach(() => {
    window.ENV = {}
  })

  it('it opens the API key modal when API key button is clicked', async () => {
    await userEvent.click(
      screen.getByRole('menuitem', {
        name: /create an api key/i,
      })
    )

    expect(actions.developerKeysModalOpen).toHaveBeenCalled()
  })

  it('it opens the LTI key modal when LTI key button is clicked', async () => {
    await userEvent.click(
      screen.getByRole('menuitem', {
        name: /create an lti key/i,
      })
    )

    expect(actions.ltiKeysSetLtiKey).toHaveBeenCalled()
    expect(actions.developerKeysModalOpen).toHaveBeenCalled()
  })
})
