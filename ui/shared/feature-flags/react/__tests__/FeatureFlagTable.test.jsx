// @vitest-environment jsdom
/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {render, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import fetchMock from 'fetch-mock'
import fakeEnv from '@canvas/test-utils/fakeENV'

import FeatureFlagTable from '../FeatureFlagTable'
import sampleData from './sampleData.json'

const rows = [
  sampleData.allowedOnFeature,
  sampleData.allowedFeature,
  sampleData.betaFeature,
  sampleData.onFeature,
  sampleData.offFeature,
  sampleData.siteAdminOnFeature,
  sampleData.siteAdminOffFeature,
  sampleData.shadowedRootAccountFeature,
]
const title = 'Section 123'

const wrapper = (rows, title) => {
  return render(<FeatureFlagTable rows={rows} title={title} />, {
    wrapper: ({children}) => (
      <div>
        <div id="flash_screenreader_holder" role="alert"></div>
        {children}
      </div>
    ),
  })
}

describe('feature_flags::FeatureFlagTable', () => {
  beforeEach(() => {
    fakeEnv.setup({
      FEATURES: {
        feature_flag_ui_sorting: true,
      },
    })
  })

  afterEach(() => {
    fakeEnv.teardown()
  })

  it('Shows the title', () => {
    const {getByTestId} = wrapper(rows, title)

    expect(getByTestId('ff-table-heading')).toHaveTextContent(title)
  })

  it('Sorts the features by name', () => {
    const {getAllByTestId} = wrapper(rows, title)

    expect(getAllByTestId('ff-table-row')[0]).toHaveTextContent('Beta Feature')
    expect(getAllByTestId('ff-table-row')[1]).toHaveTextContent('Feature 1')
    expect(getAllByTestId('ff-table-row')[2]).toHaveTextContent('Feature 2')
    expect(getAllByTestId('ff-table-row')[3]).toHaveTextContent('Feature 3')
    expect(getAllByTestId('ff-table-row')[4]).toHaveTextContent('Feature 4')
  })

  it('Includes the descriptions, respecting autoexpand', () => {
    const {queryByText} = wrapper(rows, title)

    expect(queryByText('This does great feature1y things')).not.toBeInTheDocument()
    expect(queryByText('This does great feature4y things')).toBeInTheDocument()
  })

  it('updates status pills dynamically', async () => {
    window.ENV.CONTEXT_BASE_URL = '/accounts/1'
    const route = `/api/v1${ENV.CONTEXT_BASE_URL}/features/flags/feature8`
    fetchMock.putOnce(route, sampleData.siteAdminOnFeature.feature_flag)

    const {getByText, getAllByTestId} = wrapper(rows, title)
    const row = getAllByTestId('ff-table-row')[5] // siteAdminOffFeature
    expect(row).toHaveTextContent('Hidden')

    const button = row.querySelectorAll('button')[1]
    await userEvent.click(button)
    await userEvent.click(getByText('Enabled'))
    await waitFor(() => expect(fetchMock.calls(route)).toHaveLength(1))
    expect(row).not.toHaveTextContent('Hidden')
  })

  describe('Status column sorting', () => {
    it('sorts by number of statuses first', async () => {
      const testRows = [
        // 2 statuses: hidden + shadow
        {
          ...sampleData.offFeature,
          feature: 'featureA',
          display_name: 'Feature A',
          shadow: true,
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureA',
            state: 'hidden',
          },
        },
        // 1 status: beta
        {
          ...sampleData.offFeature,
          feature: 'featureB',
          display_name: 'Feature B',
          beta: true,
          feature_flag: {...sampleData.offFeature.feature_flag, feature: 'featureB'},
        },
        // 0 statuses
        {
          ...sampleData.offFeature,
          feature: 'featureC',
          display_name: 'Feature C',
          feature_flag: {...sampleData.offFeature.feature_flag, feature: 'featureC'},
        },
      ]

      const {getAllByTestId, getByText} = wrapper(testRows, title)

      const statusHeader = getByText('Status')
      await userEvent.click(statusHeader)

      let displayedRows = getAllByTestId('ff-table-row')
      expect(displayedRows[0]).toHaveTextContent('Feature C') // 0
      expect(displayedRows[1]).toHaveTextContent('Feature B') // 1
      expect(displayedRows[2]).toHaveTextContent('Feature A') // 2

      await userEvent.click(statusHeader)

      displayedRows = getAllByTestId('ff-table-row')
      expect(displayedRows[0]).toHaveTextContent('Feature A') // 2
      expect(displayedRows[1]).toHaveTextContent('Feature B') // 1
      expect(displayedRows[2]).toHaveTextContent('Feature C') // 0
    })

    it('sorts alphabetically by status when count is equal (ascending)', async () => {
      const testRows = [
        // shadow
        {
          ...sampleData.offFeature,
          feature: 'featureG',
          display_name: 'Feature A',
          shadow: true,
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureG',
            state: 'allowed',
          },
        },
        // beta
        {
          ...sampleData.offFeature,
          feature: 'featureH',
          display_name: 'Feature B',
          beta: true,
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureH',
            state: 'allowed',
          },
        },
      ]

      const {getAllByTestId, getByText} = wrapper(testRows, title)

      const statusHeader = getByText('Status')
      await userEvent.click(statusHeader)
      let displayedRows = getAllByTestId('ff-table-row')

      expect(displayedRows[0]).toHaveTextContent('Feature B')
      expect(displayedRows[1]).toHaveTextContent('Feature A')

      await userEvent.click(statusHeader)
      displayedRows = getAllByTestId('ff-table-row')

      expect(displayedRows[0]).toHaveTextContent('Feature A')
      expect(displayedRows[1]).toHaveTextContent('Feature B')
    })
  })

  describe('State column sorting', () => {
    it('sorts by enabled/disabled first', async () => {
      const testRows = [
        {
          ...sampleData.onFeature,
          feature: 'featureK',
          display_name: 'Enabled Feature',
          feature_flag: {
            ...sampleData.onFeature.feature_flag,
            feature: 'featureK',
            state: 'on',
          },
        },
        {
          ...sampleData.offFeature,
          feature: 'featureL',
          display_name: 'Disabled Feature',
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureL',
            state: 'off',
          },
        },
      ]

      const {getAllByTestId, getByText} = wrapper(testRows, title)

      const stateHeader = getByText('State')
      await userEvent.click(stateHeader)

      let displayedRows = getAllByTestId('ff-table-row')
      expect(displayedRows[0]).toHaveTextContent('Disabled Feature')
      expect(displayedRows[1]).toHaveTextContent('Enabled Feature')

      await userEvent.click(stateHeader)

      displayedRows = getAllByTestId('ff-table-row')
      expect(displayedRows[0]).toHaveTextContent('Enabled Feature')
      expect(displayedRows[1]).toHaveTextContent('Disabled Feature')
    })

    it('sorts by locked status second, unlocked before locked (ascending)', async () => {
      const testRows = [
        {
          ...sampleData.offFeature,
          feature: 'featureO',
          display_name: 'Disabled Locked',
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureO',
            state: 'off',
          },
        },
        {
          ...sampleData.offFeature,
          feature: 'featureP',
          display_name: 'Disabled Unlocked',
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureP',
            state: 'allowed',
          },
        },
      ]

      const {getAllByTestId, getByText} = wrapper(testRows, title)

      const stateHeader = getByText('State')
      await userEvent.click(stateHeader)

      const displayedRows = getAllByTestId('ff-table-row')
      expect(displayedRows[0]).toHaveTextContent('Disabled Unlocked')
      expect(displayedRows[1]).toHaveTextContent('Disabled Locked')
    })

    it('sorts by locked status second, locked before unlocked (descending)', async () => {
      const testRows = [
        {
          ...sampleData.offFeature,
          feature: 'featureQ',
          display_name: 'Disabled Locked',
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureQ',
            state: 'off',
          },
        },
        {
          ...sampleData.offFeature,
          feature: 'featureR',
          display_name: 'Disabled Unlocked',
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureR',
            state: 'allowed',
          },
        },
      ]

      const {getAllByTestId, getByText} = wrapper(testRows, title)

      const stateHeader = getByText('State')
      await userEvent.click(stateHeader) // ascending
      await userEvent.click(stateHeader) // descending

      const displayedRows = getAllByTestId('ff-table-row')
      expect(displayedRows[0]).toHaveTextContent('Disabled Locked')
      expect(displayedRows[1]).toHaveTextContent('Disabled Unlocked')
    })

    it('sorts enabled features by locked status (ascending)', async () => {
      const testRows = [
        {
          ...sampleData.onFeature,
          feature: 'featureS',
          display_name: 'Enabled Locked',
          feature_flag: {
            ...sampleData.onFeature.feature_flag,
            feature: 'featureS',
            state: 'on',
          },
        },
        {
          ...sampleData.onFeature,
          feature: 'featureT',
          display_name: 'Enabled Unlocked',
          feature_flag: {
            ...sampleData.onFeature.feature_flag,
            feature: 'featureT',
            state: 'allowed_on',
          },
        },
      ]

      const {getAllByTestId, getByText} = wrapper(testRows, title)

      const stateHeader = getByText('State')
      await userEvent.click(stateHeader)

      const displayedRows = getAllByTestId('ff-table-row')
      expect(displayedRows[0]).toHaveTextContent('Enabled Unlocked')
      expect(displayedRows[1]).toHaveTextContent('Enabled Locked')
    })

    it('sorts by allows defaults when enablement state matches, non-lockable before lockable (ascending)', async () => {
      const testRows = [
        {
          ...sampleData.offFeature,
          feature: 'featureU',
          display_name: 'Disabled Allows Defaults',
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureU',
            state: 'off',
            transitions: {
              on: {
                locked: false,
              },
              allowed: {
                locked: false,
              },
              allowed_on: {
                locked: false,
              },
            },
          },
        },
        {
          ...sampleData.offFeature,
          feature: 'featureV',
          display_name: 'Disabled No Defaults',
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureV',
            state: 'off',
            transitions: {
              on: {
                locked: false,
              },
            },
          },
        },
      ]

      const {getAllByTestId, getByText} = wrapper(testRows, title)

      const stateHeader = getByText('State')
      await userEvent.click(stateHeader)

      const displayedRows = getAllByTestId('ff-table-row')
      expect(displayedRows[0]).toHaveTextContent('Disabled No Defaults')
      expect(displayedRows[1]).toHaveTextContent('Disabled Allows Defaults')
    })
  })

  describe('when feature_flag_ui_sorting is disabled', () => {
    beforeEach(() => {
      fakeEnv.setup({
        FEATURES: {
          feature_flag_ui_sorting: false,
        },
      })
    })

    it('does not sort when clicking on status header', async () => {
      const testRows = [
        {
          ...sampleData.offFeature,
          feature: 'featureX',
          display_name: 'Feature X',
          shadow: true,
          feature_flag: {
            ...sampleData.offFeature.feature_flag,
            feature: 'featureX',
            state: 'hidden',
          },
        },
        {
          ...sampleData.offFeature,
          feature: 'featureY',
          display_name: 'Feature Y',
          beta: true,
          feature_flag: {...sampleData.offFeature.feature_flag, feature: 'featureY'},
        },
        {
          ...sampleData.offFeature,
          feature: 'featureZ',
          display_name: 'Feature Z',
          feature_flag: {...sampleData.offFeature.feature_flag, feature: 'featureZ'},
        },
      ]

      const {getAllByTestId, getByText} = wrapper(testRows, title)

      const initialRows = getAllByTestId('ff-table-row')
      expect(initialRows[0]).toHaveTextContent('Feature X')
      expect(initialRows[1]).toHaveTextContent('Feature Y')
      expect(initialRows[2]).toHaveTextContent('Feature Z')

      const statusHeader = getByText('Status')
      await userEvent.click(statusHeader)

      const rowsAfterClick = getAllByTestId('ff-table-row')
      expect(rowsAfterClick[0]).toHaveTextContent('Feature X')
      expect(rowsAfterClick[1]).toHaveTextContent('Feature Y')
      expect(rowsAfterClick[2]).toHaveTextContent('Feature Z')
    })
  })

  describe('early access program', () => {
    const earlyAccessFeature = {
      feature: 'early_access_feature',
      applies_to: 'RootAccount',
      display_name: 'Early Access Feature',
      description: 'This is an early access feature',
      early_access_program: true,
      feature_flag: {
        feature: 'early_access_feature',
        state: 'allowed',
        transitions: {
          off: {locked: false},
          on: {locked: false},
          allowed_on: {locked: false},
        },
        locked: false,
        hidden: false,
        parent_state: 'allowed',
      },
      type: 'setting',
    }

    beforeEach(() => {
      fakeEnv.setup({
        CONTEXT_BASE_URL: '/accounts/1',
        EARLY_ACCESS_PROGRAM: false, // Start with terms not accepted
        FEATURES: {
          feature_flag_ui_sorting: true,
        },
      })
    })

    afterEach(() => {
      fakeEnv.teardown()
      fetchMock.restore()
    })

    it('shows early access modal when enabling early access feature for first time', async () => {
      const eapRoute = `/api/v1${ENV.CONTEXT_BASE_URL}/features/early_access_program`
      const flagRoute = `/api/v1${ENV.CONTEXT_BASE_URL}/features/flags/early_access_feature`

      fetchMock.postOnce(eapRoute, {early_access_program: true})
      fetchMock.putOnce(flagRoute, {
        ...earlyAccessFeature.feature_flag,
        state: 'allowed_on',
      })

      const {getByText, getByTestId, queryByText} = wrapper([earlyAccessFeature], title)

      const row = getByTestId('ff-table-row')
      const button = row.querySelectorAll('button')[1]
      await userEvent.click(button)

      await userEvent.click(getByText('Enabled'))

      await waitFor(() => {
        expect(getByText('Early Access Program Terms and Conditions')).toBeInTheDocument()
      })

      const acceptButton = getByTestId('eap-accept-button')
      await userEvent.click(acceptButton)

      await waitFor(() => {
        expect(fetchMock.called(eapRoute)).toBe(true)
        expect(fetchMock.called(flagRoute)).toBe(true)
      })

      await waitFor(() => {
        expect(queryByText('Early Access Program Terms and Conditions')).not.toBeInTheDocument()
      })
    })

    it('does not change feature flag when user cancels early access modal', async () => {
      const flagRoute = `/api/v1${ENV.CONTEXT_BASE_URL}/features/flags/early_access_feature`

      const {getByText, getByTestId, queryByText} = wrapper([earlyAccessFeature], title)

      const row = getByTestId('ff-table-row')
      const button = row.querySelectorAll('button')[1]
      await userEvent.click(button)
      await userEvent.click(getByText('Enabled'))

      await waitFor(() => {
        expect(getByText('Early Access Program Terms and Conditions')).toBeInTheDocument()
      })

      const cancelButton = getByTestId('eap-cancel-button')
      await userEvent.click(cancelButton)

      await waitFor(() => {
        expect(queryByText('Early Access Program Terms and Conditions')).not.toBeInTheDocument()
      })

      expect(fetchMock.called(flagRoute)).toBe(false)
    })

    it('skips modal when early access terms already accepted', async () => {
      fakeEnv.setup({
        CONTEXT_BASE_URL: '/accounts/1',
        EARLY_ACCESS_PROGRAM: true,
        FEATURES: {
          feature_flag_ui_sorting: true,
        },
      })

      const flagRoute = `/api/v1${ENV.CONTEXT_BASE_URL}/features/flags/early_access_feature`

      fetchMock.putOnce(flagRoute, {
        ...earlyAccessFeature.feature_flag,
        state: 'allowed_on',
      })

      const {getByText, getByTestId, queryByText} = wrapper([earlyAccessFeature], title)

      const row = getByTestId('ff-table-row')
      const button = row.querySelectorAll('button')[1]
      await userEvent.click(button)
      await userEvent.click(getByText('Enabled'))

      expect(queryByText('Early Access Program Terms and Conditions')).not.toBeInTheDocument()

      await waitFor(() => {
        expect(fetchMock.called(flagRoute)).toBe(true)
      })
    })

    it('does not show modal for non-early access features', async () => {
      const regularFeature = {...earlyAccessFeature, early_access_program: false}
      const flagRoute = `/api/v1${ENV.CONTEXT_BASE_URL}/features/flags/early_access_feature`

      fetchMock.putOnce(flagRoute, {
        ...regularFeature.feature_flag,
        state: 'allowed_on',
      })

      const {getByText, getByTestId, queryByText} = wrapper([regularFeature], title)

      const row = getByTestId('ff-table-row')
      const button = row.querySelectorAll('button')[1]
      await userEvent.click(button)
      await userEvent.click(getByText('Enabled'))

      expect(queryByText('Early Access Program Terms and Conditions')).not.toBeInTheDocument()

      await waitFor(() => {
        expect(fetchMock.called(flagRoute)).toBe(true)
      })
    })
  })
})
