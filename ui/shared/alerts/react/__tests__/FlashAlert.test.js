/*
 * Copyright (C) 2022 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 *
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
import FlashAlert from '../FlashAlert'

describe('FlashAlert', () => {
  it('renders', () => {
    render(
      <FlashAlert
        message="This is a test error message 123"
        timeout={ENV.flashAlertTimeout}
        error={new Error('This is a test error 321')}
        variant="error"
        onClose={() => {}}
        screenReaderOnly={false}
      />
    )
    expect(screen.getAllByText('This is a test error message 123')[0]).toBeInTheDocument()
    expect(screen.getAllByText('This is a test error 321')[0]).toBeInTheDocument()
  })

  it('renders, but does not show loading chunk text', () => {
    render(
      <FlashAlert
        message="This is a test error message 234"
        timeout={ENV.flashAlertTimeout}
        error={new Error('loading chunk 123')}
        variant="error"
        onClose={() => {}}
        screenReaderOnly={false}
      />
    )
    expect(screen.getAllByText('This is a test error message 234')[0]).toBeInTheDocument()
    expect(screen.queryByText('loading chunk', {exact: false})).toBeNull()
  })
})
