// /*
//  * Copyright (C) 2020 - present Instructure, Inc.
//  *
//  * This file is part of Canvas.
//  *
//  * Canvas is free software: you can redistribute it and/or modify it under
//  * the terms of the GNU Affero General Public License as published by the Free
//  * Software Foundation, version 3 of the License.
//  *
//  * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
//  * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
//  * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
//  * details.
//  *
//  * You should have received a copy of the GNU Affero General Public License along
//  * with this program. If not, see <http://www.gnu.org/licenses/>.
//  */

import React from 'react'
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {http, HttpResponse} from 'msw'
import {setupServer} from 'msw/node'
import fakeENV from '@canvas/test-utils/fakeENV'

import FeatureFlagButton from '../FeatureFlagButton'
import sampleData from './sampleData.json'

const server = setupServer()

beforeAll(() => server.listen())
afterEach(() => server.resetHandlers())
afterAll(() => server.close())

describe('feature_flags::FeatureFlagButton', () => {
  const originalEnv = JSON.parse(JSON.stringify(window.ENV))

  afterEach(() => {
    window.ENV = originalEnv
  })

  it('Renders the correct icons for on state', () => {
    const {container} = render(
      <FeatureFlagButton featureFlag={sampleData.onFeature.feature_flag} />,
    )
    expect(container.querySelector('svg[name="IconPublish"]')).toBeInTheDocument()
    expect(container.querySelector('svg[name="IconLock"]')).toBeInTheDocument()
  })

  it('Renders the correct icons for allowed state', () => {
    const {container} = render(
      <FeatureFlagButton featureFlag={sampleData.allowedFeature.feature_flag} />,
    )
    expect(container.querySelector('svg[name="IconTrouble"]')).toBeInTheDocument()
    expect(container.querySelector('svg[name="IconUnlock"]')).toBeInTheDocument()
  })

  it('Shows the lock and menu item for allowed without disableDefaults ', async () => {
    const {container, getByText} = render(
      <FeatureFlagButton featureFlag={sampleData.allowedFeature.feature_flag} />,
    )
    expect(container.querySelector('svg[name="IconUnlock"]')).toBeInTheDocument()
    await userEvent.click(container.querySelector('button'))
    expect(getByText('Lock')).toBeInTheDocument()
  })

  it('Hides the lock and menu item for allowed with disableDefaults', async () => {
    const {container, queryByText} = render(
      <FeatureFlagButton
        featureFlag={sampleData.allowedFeature.feature_flag}
        disableDefaults={true}
      />,
    )
    expect(container.querySelector('svg[name="IconUnlock"]')).not.toBeInTheDocument()
    await userEvent.click(container.querySelector('button'))
    expect(queryByText('Lock')).not.toBeInTheDocument()
  })

  it('Calls the set flag api for enabling and uses the returned flag', async () => {
    window.ENV.CONTEXT_BASE_URL = '/accounts/1'
    const apiCalled = vi.fn()
    server.use(
      http.put('/api/v1/accounts/1/features/flags/feature1', () => {
        apiCalled()
        return HttpResponse.json(sampleData.onFeature.feature_flag)
      }),
    )
    const onStateChange = vi.fn()
    const {container, getByText} = render(
      <FeatureFlagButton
        featureFlag={sampleData.allowedFeature.feature_flag}
        onStateChange={onStateChange}
      />,
    )

    expect(container.querySelector('svg[name="IconTrouble"]')).toBeInTheDocument()
    await userEvent.click(container.querySelector('button'))
    await userEvent.click(getByText('Enabled'))
    await waitFor(() => expect(apiCalled).toHaveBeenCalledTimes(1))

    expect(onStateChange).toHaveBeenCalledWith('on')
    expect(container.querySelector('svg[name="IconPublish"]')).toBeInTheDocument()
  })

  it('Calls the delete api when appropriate and uses the returned flag', async () => {
    ENV.CONTEXT_BASE_URL = '/accounts/1'
    const apiCalled = vi.fn()
    server.use(
      http.delete('/api/v1/accounts/1/features/flags/feature1', () => {
        apiCalled()
        return HttpResponse.json(sampleData.allowedFeature.feature_flag)
      }),
    )
    const {container, getByText} = render(
      <FeatureFlagButton featureFlag={sampleData.allowedFeature.feature_flag} />,
    )

    expect(container.querySelector('svg[name="IconTrouble"]')).toBeInTheDocument()
    await userEvent.click(container.querySelector('button'))
    await userEvent.click(getByText('Disabled'))
    await waitFor(() => expect(apiCalled).toHaveBeenCalledTimes(1))

    expect(container.querySelector('svg[name="IconTrouble"]')).toBeInTheDocument()
  })

  // FOO-3819
  it.skip('Refocuses on the button after the FF icon changes', async () => {
    ENV.CONTEXT_BASE_URL = '/accounts/1'
    server.use(
      http.put('/api/v1/accounts/1/features/flags/feature4', () => {
        return HttpResponse.json(sampleData.onFeature.feature_flag)
      }),
    )
    const {container, getByText, getByRole} = render(
      <div id="ff-test-button-enclosing-div">
        <FeatureFlagButton featureFlag={sampleData.offFeature.feature_flag} />
      </div>,
    )
    container.querySelector('#ff-test-button-enclosing-div').focus()
    await userEvent.click(getByRole('button'))
    await userEvent.click(getByText('Enabled'))
    await waitFor(() =>
      expect(container.querySelector('svg[name="IconPublish"]')).toBeInTheDocument(),
    )
    const button = container.querySelector('button')
    const areSameElement = document.activeElement === button
    expect(areSameElement).toBeTruthy()
  })

  describe('and the context is site admin', () => {
    beforeEach(() => {
      fakeENV.setup({
        ...fakeENV.ENV,
        ACCOUNT: {
          site_admin: true,
        },
        RAILS_ENVIRONMENT: 'production',
        CONTEXT_BASE_URL: '/accounts/site_admin',
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('renders a confirmation modal to prevent accidental updates in non-development environments', async () => {
      const user = userEvent.setup()
      const apiCalled = vi.fn()
      server.use(
        http.put('/api/v1/accounts/site_admin/features/flags/feature1', () => {
          apiCalled()
          return HttpResponse.json(sampleData.onFeature.feature_flag)
        }),
      )

      const {container, getByText, getByTestId, queryByText} = render(
        <FeatureFlagButton
          featureFlag={sampleData.allowedFeature.feature_flag}
          displayName="Test Feature"
        />,
      )

      await user.click(container.querySelector('button'))
      await user.click(getByText('Enabled'))

      expect(
        await waitFor(() => getByText('Environment Confirmation for Test Feature')),
      ).toBeInTheDocument()

      const input = getByTestId('confirm-prompt-input')

      // Try with incorrect environment
      await user.click(input)
      await user.paste('beta')
      await user.click(getByText(/^Confirm/i).closest('button'))

      expect(await waitFor(() => getByText(/The provided value is incorrect/i))).toBeInTheDocument()

      // Try with correct environment
      await user.click(input)
      await user.clear(input)
      await user.paste('production')
      await user.click(getByText(/^Confirm/i).closest('button'))

      // Confirmation modal should disappear and API should be called
      await waitFor(() => {
        expect(queryByText(/Environment Confirmation/i)).not.toBeInTheDocument()
      })
      await waitFor(() => expect(apiCalled).toHaveBeenCalledTimes(1))
    })

    it('does not call the API if the confirmation is cancelled', async () => {
      const user = userEvent.setup()
      const apiCalled = vi.fn()
      server.use(
        http.put('/api/v1/accounts/site_admin/features/flags/feature1', () => {
          apiCalled()
          return HttpResponse.json(sampleData.onFeature.feature_flag)
        }),
      )

      const {container, getByText, queryByText} = render(
        <FeatureFlagButton
          featureFlag={sampleData.allowedFeature.feature_flag}
          displayName="Test Feature"
        />,
      )

      await user.click(container.querySelector('button'))

      await user.click(getByText('Enabled'))

      expect(
        await waitFor(() => getByText('Environment Confirmation for Test Feature')),
      ).toBeInTheDocument()

      await user.click(getByText(/^Cancel/i).closest('button'))

      // Confirmation modal should disappear but API should not be called
      await waitFor(() => {
        expect(queryByText(/Environment Confirmation/i)).not.toBeInTheDocument()
      })
      expect(apiCalled).not.toHaveBeenCalled()
    })
  })

  describe('and the context is site admin in development', () => {
    beforeEach(() => {
      fakeENV.setup({
        ...fakeENV.ENV,
        ACCOUNT: {
          site_admin: true,
        },
        RAILS_ENVIRONMENT: 'development',
        CONTEXT_BASE_URL: '/accounts/site_admin',
      })
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('does not show confirmation modal in development environment', async () => {
      const user = userEvent.setup()
      const apiCalled = vi.fn()
      server.use(
        http.put('/api/v1/accounts/site_admin/features/flags/feature1', () => {
          apiCalled()
          return HttpResponse.json(sampleData.onFeature.feature_flag)
        }),
      )

      const {container, getByText, queryByText} = render(
        <FeatureFlagButton
          featureFlag={sampleData.allowedFeature.feature_flag}
          displayName="Test Feature"
        />,
      )

      await user.click(container.querySelector('button'))
      await user.click(getByText('Enabled'))

      // Should not show the environment confirmation dialog
      expect(queryByText(/Environment Confirmation/i)).not.toBeInTheDocument()

      // API should be called directly
      await waitFor(() => expect(apiCalled).toHaveBeenCalledTimes(1))
    })
  })

  describe('early access program', () => {
    beforeEach(() => {
      fakeENV.setup({
        ...fakeENV.ENV,
        CONTEXT_BASE_URL: '/accounts/1',
      })
    })

    afterEach(() => {
      fakeENV.teardown()
      vi.clearAllMocks()
    })

    it('skips the API update when checkEarlyAccessProgram returns false', async () => {
      const user = userEvent.setup()
      const apiCalled = vi.fn()
      const checkEarlyAccessProgram = vi.fn()

      server.use(
        http.put('/api/v1/accounts/1/features/flags/feature1', () => {
          apiCalled()
          return HttpResponse.json(sampleData.onFeature.feature_flag)
        }),
      )
      checkEarlyAccessProgram.mockResolvedValue(false)

      const {container, getByText} = render(
        <FeatureFlagButton
          featureFlag={sampleData.allowedFeature.feature_flag}
          displayName="Early Access Feature"
          checkEarlyAccessProgram={checkEarlyAccessProgram}
        />,
      )

      await user.click(container.querySelector('button'))
      await user.click(getByText('Enabled'))

      await waitFor(() => {
        expect(checkEarlyAccessProgram).toHaveBeenCalledWith(
          sampleData.allowedFeature.feature_flag,
          'allowed_on',
        )
      })

      expect(apiCalled).not.toHaveBeenCalled()
    })
  })
})
