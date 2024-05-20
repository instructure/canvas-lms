/*
 * Copyright (C) 2023 - present Instructure, Inc.
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
import MicrosoftSyncDebugInfo from '../MicrosoftSyncDebugInfo'

jest.mock('@canvas/do-fetch-api-effect')

describe('MicrosoftSyncDebugInfo', () => {
  const props = overrides => ({
    debugInfo: [
      {timestamp: '2020-10-20T02:02:02Z', msg: 'Debug item 1', user_ids: [1, 2]},
      {timestamp: '2020-10-21T03:03:03Z', msg: 'Debug item 2'},
    ],
    ...overrides,
  })
  const subject = overrides => render(<MicrosoftSyncDebugInfo {...props(overrides)} />)

  it('renders expandable debugging info', () => {
    const {getByText} = subject()
    expect(getByText('Debugging Info (Advanced)...')).toBeInTheDocument()
  })

  it('renders the debugInfo array as a list of text items', async () => {
    // click the toggle button to expand the debugging info:
    const {getByText} = subject()
    getByText('Toggle Debugging Info').click()
    expect(getByText('Debug item 1')).toBeInTheDocument()
    expect(getByText('Debug item 2')).toBeInTheDocument()
    expect(getByText(/Oct 20/)).toBeInTheDocument()
    expect(getByText(/2:02/)).toBeInTheDocument()
    expect(getByText(/Oct 21/)).toBeInTheDocument()
    expect(getByText(/3:03/)).toBeInTheDocument()
  })
})
