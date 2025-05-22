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
import userEvent from '@testing-library/user-event'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {FileManagementProvider} from '../../../../contexts/FileManagementContext'
import {createMockFileManagementContext} from '../../../../__tests__/createMockContext'
import {FAKE_FILES, FAKE_FOLDERS_AND_FILES} from '../../../../../fixtures/fakeData'
import {resetAndGetFilesEnv} from '../../../../../utils/filesEnvUtils'
import {createFilesContexts} from '../../../../../fixtures/fileContexts'
import {RowsProvider} from '../../../../contexts/RowsContext'
import PermissionsModal from '../PermissionsModal'
import {
  type AvailabilityOptionId,
  DATE_RANGE_TYPE_OPTIONS,
  parseNewRows,
} from '../PermissionsModalUtils'

jest.mock('@canvas/do-fetch-api-effect')

const defaultProps = {
  open: true,
  items: FAKE_FOLDERS_AND_FILES,
  onDismiss: jest.fn(),
}

const renderComponent = (props?: any) =>
  render(
    <FileManagementProvider value={createMockFileManagementContext()}>
      <RowsProvider value={{currentRows: FAKE_FOLDERS_AND_FILES, setCurrentRows: jest.fn()}}>
        <PermissionsModal {...defaultProps} {...props} />
      </RowsProvider>
    </FileManagementProvider>,
  )

describe('PermissionsModal', () => {
  beforeAll(() => {
    const filesContexts = createFilesContexts()
    resetAndGetFilesEnv(filesContexts)
  })

  beforeEach(() => {
    // Set up a default mock implementation for doFetchApi to prevent unhandled rejections
    ;(doFetchApi as jest.Mock).mockResolvedValue({})
  })

  afterEach(() => {
    jest.clearAllMocks()
    jest.resetAllMocks()
  })

  describe('parseNewRows', () => {
    const defaultParams = {
      currentRows: [FAKE_FILES[0]],
      items: [FAKE_FILES[0]],
      availabilityOptionId: 'published' as AvailabilityOptionId,
      dateRangeType: null,
      unlockAt: null,
      lockAt: null,
    }

    it('sets a row to published', () => {
      const newRows = parseNewRows(defaultParams)
      expect(newRows).toEqual([
        {
          ...FAKE_FILES[0],
          hidden: false,
          lock_at: null,
          locked: false,
          unlock_at: null,
        },
      ])
    })

    it('sets a row to unpublished', () => {
      const newRows = parseNewRows({
        ...defaultParams,
        availabilityOptionId: 'unpublished',
      })
      expect(newRows).toEqual([
        {
          ...FAKE_FILES[0],
          hidden: false,
          lock_at: null,
          locked: true,
          unlock_at: null,
        },
      ])
    })
    it('sets a row to link_only', () => {
      const newRows = parseNewRows({
        ...defaultParams,
        availabilityOptionId: 'link_only',
      })
      expect(newRows).toEqual([
        {
          ...FAKE_FILES[0],
          hidden: true,
          lock_at: null,
          locked: false,
          unlock_at: null,
        },
      ])
    })

    it('sets a row to date_range', () => {
      const newRows = parseNewRows({
        ...defaultParams,
        dateRangeType: DATE_RANGE_TYPE_OPTIONS.range,
        availabilityOptionId: 'date_range',
        unlockAt: '2025-04-12T00:00:00Z',
        lockAt: '2025-04-15T00:00:00Z',
      })
      expect(newRows).toEqual([
        {
          ...FAKE_FILES[0],
          hidden: false,
          lock_at: '2025-04-15T00:00:00Z',
          locked: false,
          unlock_at: '2025-04-12T00:00:00Z',
        },
      ])
    })

    it('sets multiple rows', () => {
      const newRows = parseNewRows({
        ...defaultParams,
        currentRows: FAKE_FOLDERS_AND_FILES,
        items: FAKE_FOLDERS_AND_FILES,
        availabilityOptionId: 'unpublished',
      })
      expect(newRows).toEqual(
        FAKE_FOLDERS_AND_FILES.map(item => ({
          ...item,
          hidden: false,
          lock_at: null,
          locked: true,
          unlock_at: null,
        })),
      )
    })
  })
})
