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

import React from 'react'
import {render, screen, waitFor} from '@testing-library/react'
import {CompletionProgressBar} from '../completion_progress_bar'

const renderComponent = (overrideProps?: any) =>
  render(<CompletionProgressBar workflowState="queued" completion={0} {...overrideProps} />)

describe('CompletionProgressBar', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  it('renders with proper progress', async () => {
    renderComponent({workflowState: 'running', completion: 75})
    await waitFor(() => expect(screen.getByRole('progressbar')).toHaveAttribute('value', '75'))
  })

  it('does not render when the migration is complete', async () => {
    renderComponent({workflowState: 'completed'})
    await waitFor(() => expect(document.body.firstChild).toBeEmptyDOMElement())
  })

  it('does not render when the migration is failed', async () => {
    renderComponent({workflowState: 'failed'})
    await waitFor(() => expect(document.body.firstChild).toBeEmptyDOMElement())
  })
})
