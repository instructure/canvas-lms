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

import React from 'react'
import {render} from '@testing-library/react'
import SyncHistory from '../SyncHistory'
import getSampleData from './getSampleData'

const SyncHistoryComponent = SyncHistory as unknown as React.ComponentType<Record<string, unknown>>

describe('SyncHistory component', () => {
  const defaultProps = (): React.ComponentProps<typeof SyncHistory> => ({
    loadHistory: () => {},
    isLoadingHistory: false,
    hasLoadedHistory: false,
    loadAssociations: () => {},
    isLoadingAssociations: false,
    hasLoadedAssociations: false,
    associations: [] as never[],
    migrations: getSampleData().history as unknown as React.ComponentProps<
      typeof SyncHistory
    >['migrations'],
  })

  test('renders the SyncHistory component', () => {
    const {container} = render(<SyncHistoryComponent {...defaultProps()} />)
    const node = container.querySelector('.bcs__history')
    expect(node).toBeTruthy()
  })

  test('displays spinner when loading courses', () => {
    const props = defaultProps()
    props.isLoadingHistory = true
    const {container} = render(<SyncHistoryComponent {...props} />)
    const spinner = container.querySelector('svg[role="img"]')
    expect(spinner).toBeTruthy()
  })

  test('renders SyncHistoryItem components for each migration', () => {
    const tree = render(<SyncHistoryComponent {...defaultProps()} />)
    const node = tree.container.querySelectorAll('.bcs__history-item')
    expect(node).toHaveLength(1)
  })
})
