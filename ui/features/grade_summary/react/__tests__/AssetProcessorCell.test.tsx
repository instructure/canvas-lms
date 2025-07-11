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

import React from 'react'
import {render, screen} from '@testing-library/react'
import AssetProcessorCell from '../AssetProcessorCell'
import {ExistingAttachedAssetProcessor} from '@canvas/lti/model/AssetProcessor'

describe('AssetProcessorCell', () => {
  const mockAssetProcessors: ExistingAttachedAssetProcessor[] = [
    {
      id: 1,
      tool_id: 2,
      tool_name: 'Test Tool',
      title: 'Test Asset Processor',
    },
  ]

  it('renders with empty asset reports array', () => {
    render(<AssetProcessorCell assetProcessors={mockAssetProcessors} assetReports={[]} />)

    expect(screen.getByText('No result')).toBeInTheDocument()
  })
})
