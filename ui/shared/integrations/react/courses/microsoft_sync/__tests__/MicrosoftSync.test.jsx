/*
 * Copyright (C) 2021 - present Instructure, Inc.
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
import MicrosoftSync from '../MicrosoftSync'

describe('MicrosoftSync', () => {
  const props = overrides => ({
    enabled: true,
    group: {
      last_synced_at: 'Tue, 30 Mar 2021 20:44:10 UTC +00:00',
      workflow_state: 'completed',
    },
    loading: false,
    ...overrides,
  })
  const subject = overrides => render(<MicrosoftSync {...props(overrides)} />)

  it('displays the last sync time', () => {
    expect(subject().getByText(/Mar 3/).textContent).toEqual(' Mar 30, 2021 at 8:44pm')
  })

  it('displays the workflow state', () => {
    expect(subject().getByText('Sync completed successfully')).toBeInTheDocument()
  })

  it('indicates there are no errors', () => {
    expect(subject().getByText('No errors')).toBeInTheDocument()
  })

  describe('when a sync has never occurred', () => {
    const overrides = {group: {...props().group, workflow_state: 'pending', last_synced_at: null}}

    it('indicates a sync has never occurred', () => {
      expect(subject(overrides).getByText('never')).toBeInTheDocument()
    })
  })

  describe('when "loading" is true', () => {
    const overrides = {loading: true}

    it('renders a spinner', () => {
      expect(subject(overrides).getByText('Loading Microsoft sync data')).toBeTruthy()
    })
  })

  describe('when there are errors', () => {
    const overrides = {group: {...props().group, workflow_state: 'errored'}}

    it('does not indicate "no errors"', () => {
      expect(subject(overrides).queryByText('No errors')).not.toBeInTheDocument()
    })
  })
})
