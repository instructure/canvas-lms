/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {render, screen} from '@testing-library/react'
import {PreviewAndSidebar} from '../PreviewAndSidebar'

describe('PreviewAndSidebar', () => {
  it('renders the preview iframe with the given src', () => {
    render(<PreviewAndSidebar previewUrl="https://example.com/preview" />)
    expect(screen.getByTestId('preview-iframe')).toHaveAttribute(
      'src',
      'https://example.com/preview',
    )
  })

  // this is the mechanism that prevents the race condition where the iframe
  // could signal DISCOVERY_PAGE_READY before ConfigureModal has fetched its
  // config
  //
  // ConfigureModal passes previewUrl={isLoadingConfig ? undefined : previewUrl},
  // so the iframe is not loaded (and cannot send READY) until real data is available
  it('renders the preview iframe without a src when previewUrl is not provided', () => {
    render(<PreviewAndSidebar />)
    expect(screen.getByTestId('preview-iframe')).not.toHaveAttribute('src')
  })
})
