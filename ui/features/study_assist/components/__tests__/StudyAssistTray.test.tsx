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

import React from 'react'
import {render, screen, fireEvent} from '@testing-library/react'
import StudyAssistTray from '../StudyAssistTray'

vi.mock('@instructure/platform-study-assist', () => ({
  AssistProvider: ({children, moduleItemId}: {children: React.ReactNode; moduleItemId: string}) => (
    <div data-testid="assist-provider" data-module-item-id={moduleItemId}>
      {children}
    </div>
  ),
  AssistContent: () => <div data-testid="assist-content" />,
}))

describe('StudyAssistTray', () => {
  const onDismiss = vi.fn()
  const fetchAssistResponse = vi.fn()

  beforeEach(() => {
    window.ENV = {
      ...window.ENV,
      COURSE_ID: '123',
      WIKI_PAGE_ID: 'test-page',
    } as any
    onDismiss.mockReset()
  })

  it('renders the heading when open', () => {
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    expect(screen.getByText('Study tools')).toBeInTheDocument()
  })

  it('calls onDismiss when close button is clicked', () => {
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    const closeEl = screen.getByTestId('study-assist-close-button')
    const button = closeEl.tagName === 'BUTTON' ? closeEl : closeEl.querySelector('button')
    fireEvent.click(button!)
    expect(onDismiss).toHaveBeenCalledTimes(1)
  })

  it('passes WIKI_PAGE_ID as moduleItemId to AssistProvider', () => {
    render(
      <StudyAssistTray
        open={true}
        onDismiss={onDismiss}
        fetchAssistResponse={fetchAssistResponse}
      />,
    )
    expect(screen.getByTestId('assist-provider')).toHaveAttribute(
      'data-module-item-id',
      'test-page',
    )
  })
})
