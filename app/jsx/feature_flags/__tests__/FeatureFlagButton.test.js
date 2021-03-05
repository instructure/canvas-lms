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
import {render, fireEvent, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'

import FeatureFlagButton from '../FeatureFlagButton'
import sampleData from './sampleData.json'

describe('feature_flags::FeatureFlagButton', () => {
  afterEach(() => {
    fetchMock.restore()
  })

  it('Renders the correct icons for on state', () => {
    const {container} = render(
      <FeatureFlagButton featureFlag={sampleData.onFeature.feature_flag} />
    )
    expect(container.querySelector('svg[name="IconPublish"]')).toBeInTheDocument()
    expect(container.querySelector('svg[name="IconLock"]')).toBeInTheDocument()
  })

  it('Renders the correct icons for allowed state', () => {
    const {container} = render(
      <FeatureFlagButton featureFlag={sampleData.allowedFeature.feature_flag} />
    )
    expect(container.querySelector('svg[name="IconTrouble"]')).toBeInTheDocument()
    expect(container.querySelector('svg[name="IconUnlock"]')).toBeInTheDocument()
  })

  it('Shows the lock and menu item for allowed without disableDefaults ', () => {
    const {container, getByText} = render(
      <FeatureFlagButton featureFlag={sampleData.allowedFeature.feature_flag} />
    )
    expect(container.querySelector('svg[name="IconUnlock"]')).toBeInTheDocument()
    expect(getByText('Lock')).toBeInTheDocument()
  })

  it('Hides the lock and menu item for allowed with disableDefaults', () => {
    const {container, queryByText} = render(
      <FeatureFlagButton featureFlag={sampleData.allowedFeature.feature_flag} disableDefaults />
    )
    expect(container.querySelector('svg[name="IconUnlock"]')).not.toBeInTheDocument()
    expect(queryByText('Lock')).not.toBeInTheDocument()
  })

  it('Calls the set flag api for enabling and uses the returned flag', async () => {
    ENV.CONTEXT_BASE_URL = '/accounts/1'
    const route = `/api/v1${ENV.CONTEXT_BASE_URL}/features/flags/feature1`
    fetchMock.putOnce(route, JSON.stringify(sampleData.onFeature.feature_flag))
    const {container, getByText} = render(
      <FeatureFlagButton featureFlag={sampleData.allowedFeature.feature_flag} />
    )

    expect(container.querySelector('svg[name="IconTrouble"]')).toBeInTheDocument()
    fireEvent.click(getByText('Enabled'))
    await waitFor(() => expect(fetchMock.calls(route)).toHaveLength(1))

    expect(container.querySelector('svg[name="IconPublish"]')).toBeInTheDocument()
  })

  it('Calls the delete api when appropriate and uses the returned flag', async () => {
    ENV.CONTEXT_BASE_URL = '/accounts/1'
    const route = `/api/v1${ENV.CONTEXT_BASE_URL}/features/flags/feature1`
    fetchMock.deleteOnce(route, JSON.stringify(sampleData.allowedFeature.feature_flag))
    const {container, getByText} = render(
      <FeatureFlagButton featureFlag={sampleData.allowedFeature.feature_flag} />
    )

    expect(container.querySelector('svg[name="IconTrouble"]')).toBeInTheDocument()
    fireEvent.click(getByText('Disabled'))
    await waitFor(() => expect(fetchMock.calls(route)).toHaveLength(1))

    expect(container.querySelector('svg[name="IconTrouble"]')).toBeInTheDocument()
  })
})
