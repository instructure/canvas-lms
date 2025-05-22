/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {render, screen, waitFor} from '@testing-library/react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import userEvent from '@testing-library/user-event'
import UsageRightsModal from '../UsageRightsModal'
import {FAKE_FILES, FAKE_FOLDERS, FAKE_FOLDERS_AND_FILES} from '../../../../../fixtures/fakeData'
import {createMockFileManagementContext} from '../../../../__tests__/createMockContext'
import {FileManagementProvider} from '../../../../contexts/FileManagementContext'
import {RowsProvider} from '../../../../contexts/RowsContext'
import {parseNewRows} from '../UsageRightsModalUtils'

jest.mock('@canvas/do-fetch-api-effect')

const MOCK_LICENSES = [
  {
    id: 'private',
    name: 'Private (Copyrighted)',
    url: 'http://en.wikipedia.org/wiki/Copyright',
  },
  {
    id: 'public_domain',
    name: 'Public Domain',
    url: 'http://en.wikipedia.org/wiki/Public_domain',
  },
  {
    id: 'cc_by',
    name: 'CC Attribution',
    url: 'http://creativecommons.org/licenses/by/4.0',
  },
  {
    id: 'cc_by_sa',
    name: 'CC Attribution Share Alike',
    url: 'http://creativecommons.org/licenses/by-sa/4.0',
  },
  {
    id: 'cc_by_nc',
    name: 'CC Attribution Non-Commercial',
    url: 'http://creativecommons.org/licenses/by-nc/4.0',
  },
  {
    id: 'cc_by_nc_sa',
    name: 'CC Attribution Non-Commercial Share Alike',
    url: 'http://creativecommons.org/licenses/by-nc-sa/4.0',
  },
  {
    id: 'cc_by_nd',
    name: 'CC Attribution No Derivatives',
    url: 'http://creativecommons.org/licenses/by-nd/4.0',
  },
  {
    id: 'cc_by_nc_nd',
    name: 'CC Attribution Non-Commercial No Derivatives',
    url: 'http://creativecommons.org/licenses/by-nc-nd/4.0/',
  },
]

const defaultProps = {
  open: true,
  items: FAKE_FOLDERS_AND_FILES,
  onDismiss: jest.fn(),
}

const renderComponent = (props: any = defaultProps) =>
  render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <RowsProvider value={{currentRows: props.items, setCurrentRows: jest.fn()}}>
        <UsageRightsModal {...defaultProps} {...props} />
      </RowsProvider>
    </FileManagementProvider>,
  )

describe('UsageRightsModal', () => {
  beforeEach(() => {
    // Reset and clear mocks before each test to ensure clean state
    jest.clearAllMocks()
    jest.resetAllMocks()
    // Set up the mock for the licenses fetch that happens on component mount
    ;(doFetchApi as jest.Mock).mockImplementation((params: any) => {
      if (params.path && params.path.includes('content_licenses')) {
        return Promise.resolve({json: MOCK_LICENSES})
      }
      return Promise.resolve({})
    })
  })

  afterEach(() => {
    // Clean up after each test
    jest.clearAllMocks()
    jest.resetAllMocks()
  })

  // TODO: RCX-3380
  xit('fails fetch request and shows alert', async () => {
    // Reset mock implementation for this specific test
    jest.clearAllMocks()
    jest.resetAllMocks()

    // Set up the license fetch that happens on component mount
    ;(doFetchApi as jest.Mock).mockImplementationOnce((params: any) => {
      if (params.path && params.path.includes('content_licenses')) {
        return Promise.resolve({json: MOCK_LICENSES})
      }
      return Promise.resolve({})
    })

    // Set up the PUT request to fail for the second call
    ;(doFetchApi as jest.Mock).mockImplementationOnce((params: any) => {
      if (params.method === 'PUT' && params.path.includes('usage_rights')) {
        return Promise.reject(new Error('Failed to set usage rights'))
      }
      return Promise.resolve({})
    })

    renderComponent()

    await userEvent.click(await screen.findByTestId('usage-rights-justification-selector'))
    await userEvent.click(await screen.findByText('I hold the copyright'))
    await userEvent.type(await screen.findByTestId('usage-rights-holder-input'), 'acme inc')

    // Click save button to trigger the PUT request
    await userEvent.click(await screen.findByTestId('usage-rights-save-button'))

    // Wait for the error message to appear
    await waitFor(() => {
      expect(screen.getAllByText(/there was an error setting usage rights/i)[0]).toBeInTheDocument()
    })

    // Verify the API was called with the correct parameters
    expect(doFetchApi).toHaveBeenCalledWith({
      method: 'PUT',
      path: '/api/v1/courses/2/usage_rights',
      params: {
        folder_ids: FAKE_FOLDERS.map(f => f.id.toString()),
        file_ids: FAKE_FILES.map(f => f.id.toString()),
        usage_rights: {legal_copyright: 'acme inc', use_justification: 'own_copyright'},
      },
    })
  })

  describe('parseNewRows', () => {
    const defaultArgs = {
      items: [FAKE_FOLDERS_AND_FILES[0]],
      currentRows: [FAKE_FOLDERS_AND_FILES[0], FAKE_FOLDERS_AND_FILES[1]],
      usageRight: 'own_copyright',
      ccLicenseOption: null,
      copyrightHolder: null,
    }
    it('sets copy right to own_copyright', () => {
      const newRows = parseNewRows(defaultArgs)
      expect(newRows).toEqual([
        {
          ...FAKE_FOLDERS_AND_FILES[0],
          usage_rights: {
            use_justification: 'own_copyright',
            legal_copyright: undefined,
            license: undefined,
            license_name: 'Private (Copyrighted)',
          },
        },
        {
          ...FAKE_FOLDERS_AND_FILES[1],
        },
      ])
    })

    it('sets copy right to public_domain', () => {
      const newRows = parseNewRows({
        ...defaultArgs,
        usageRight: 'public_domain',
      })
      expect(newRows).toEqual([
        {
          ...FAKE_FOLDERS_AND_FILES[0],
          usage_rights: {
            use_justification: 'public_domain',
            legal_copyright: undefined,
            license: undefined,
            license_name: 'Public Domain',
          },
        },
        {
          ...FAKE_FOLDERS_AND_FILES[1],
        },
      ])
    })

    it('sets copy right to creative_commons', () => {
      const newRows = parseNewRows({
        ...defaultArgs,
        usageRight: 'creative_commons',
        ccLicenseOption: 'cc_by',
      })
      expect(newRows).toEqual([
        {
          ...FAKE_FOLDERS_AND_FILES[0],
          usage_rights: {
            use_justification: 'creative_commons',
            legal_copyright: undefined,
            license: 'cc_by',
            license_name: 'CC Attribution',
          },
        },
        {
          ...FAKE_FOLDERS_AND_FILES[1],
        },
      ])
    })

    it('sets copy right for multiple items', () => {
      const newRows = parseNewRows({
        ...defaultArgs,
        items: [FAKE_FOLDERS_AND_FILES[0], FAKE_FOLDERS_AND_FILES[1]],
      })
      expect(newRows).toEqual([
        {
          ...FAKE_FOLDERS_AND_FILES[0],
          usage_rights: {
            use_justification: 'own_copyright',
            legal_copyright: undefined,
            license: undefined,
            license_name: 'Private (Copyrighted)',
          },
        },
        {
          ...FAKE_FOLDERS_AND_FILES[1],
          usage_rights: {
            use_justification: 'own_copyright',
            legal_copyright: undefined,
            license: undefined,
            license_name: 'Private (Copyrighted)',
          },
        },
      ])
    })
  })
})
