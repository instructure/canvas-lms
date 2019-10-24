/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import {render, fireEvent} from '@testing-library/react'
import ContentTypeExternalToolTray from 'compiled/views/wiki/ContentTypeExternalToolTray'

describe('ContentTypeExternalToolTray', () => {
  const tool = {id: 1, base_url: 'https://one.lti.com', title: 'First LTI'}
  const onDismiss = jest.fn()

  it('shows LTI title', () => {
    const {getByText} = render(<ContentTypeExternalToolTray tool={tool} onDismiss={onDismiss} />)
    expect(getByText(/first lti/i)).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', () => {
    const {getByText} = render(<ContentTypeExternalToolTray tool={tool} onDismiss={onDismiss} />)
    fireEvent.click(getByText('Close'))
    expect(onDismiss.mock.calls.length).toBe(1)
  })
})
