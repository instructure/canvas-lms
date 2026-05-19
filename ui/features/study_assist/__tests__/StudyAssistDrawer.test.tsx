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
import {act, render, screen} from '@testing-library/react'
import * as PendoModule from '@canvas/pendo'

vi.mock('@instructure/platform-provider', () => ({
  PlatformUiProvider: ({children}: {children: React.ReactNode}) => <>{children}</>,
}))

vi.mock('@instructure/platform-study-assist', () => ({
  AssistProvider: ({children}: {children: React.ReactNode}) => <>{children}</>,
  AssistContent: () => <div data-testid="assist-content" />,
  AssistFlashCardsInteraction: () => <div />,
  useAssistContext: () => ({showBackButton: false, resetChat: vi.fn()}),
}))

vi.mock('@canvas/ai-information', () => ({
  default: ({triggerButton}: {triggerButton: React.ReactNode}) => <div>{triggerButton}</div>,
}))

import {StudyAssistDrawer} from '../index'

describe('StudyAssistDrawer', () => {
  beforeEach(() => {
    window.ENV = {
      ...window.ENV,
      STUDY_ASSIST_TOOLS: ['Summarize'],
      LOCALE: 'en',
      TIMEZONE: 'UTC',
    } as any
    vi.spyOn(PendoModule, 'initializePendo').mockResolvedValue({track: vi.fn()})
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('appends pageContent to its host div on mount', () => {
    const pageContent = document.createElement('section')
    pageContent.setAttribute('data-testid', 'fake-page-content')
    document.body.appendChild(pageContent)

    render(<StudyAssistDrawer pageContent={pageContent} />)

    const drawerLayout = screen.getByTestId('study-assist-drawer-layout')
    expect(drawerLayout.contains(pageContent)).toBe(true)
  })

  it('opens the tray when the study-assist:open window event fires', () => {
    const pageContent = document.createElement('section')
    document.body.appendChild(pageContent)

    render(<StudyAssistDrawer pageContent={pageContent} />)

    act(() => {
      window.dispatchEvent(new CustomEvent('study-assist:open'))
    })

    expect(screen.getByTestId('study-assist-drawer-tray')).toBeInTheDocument()
  })
})
