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
import {render} from '@testing-library/react'
import {setupServer} from 'msw/node'
import {ContextModuleProvider, contextModuleDefaultProps} from '../../hooks/useModuleContext'
import ModuleHeaderUnlockAt, {ModuleHeaderUnlockAtProps} from '../ModuleHeaderUnlockAt'
import {format} from '@instructure/moment-utils'
import moment from 'moment'

const unlockAtFormat = '%b %-d at %l:%M%P'

const server = setupServer()

const setUp = (props: ModuleHeaderUnlockAtProps, courseId = 'test-course-id') => {
  const contextProps = {
    ...contextModuleDefaultProps,
    courseId,
    moduleGroupMenuTools: [],
    moduleMenuModalTools: [],
    moduleMenuTools: [],
    moduleIndexMenuModalTools: [],
  }

  return render(
    <ContextModuleProvider {...contextProps}>
      <ModuleHeaderUnlockAt {...props} />
    </ContextModuleProvider>,
  )
}

const buildDefaultProps = (
  overrides: Partial<ModuleHeaderUnlockAtProps> = {},
): ModuleHeaderUnlockAtProps => ({
  unlockAt: null,
  ...overrides,
})

beforeEach(() => {
  // eslint-disable-next-line @typescript-eslint/ban-ts-comment
  // @ts-ignore - window.ENV is a Canvas global not in TS types
  window.ENV = {
    TIMEZONE: 'UTC',
  }
})

describe('ModuleHeaderUnlockAt', () => {
  beforeAll(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterAll(() => server.close())
  it('renders when unlockAt is in the future', () => {
    const futureDate = moment().add(1, 'day').toISOString()
    setUp(buildDefaultProps({unlockAt: futureDate}))

    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore - format's third argument (zone) is optional at runtime but required by tsgo
    const formattedDate = format(futureDate, unlockAtFormat)
    const {container} = render(<ModuleHeaderUnlockAt unlockAt={futureDate} />)

    const desktopElement = container.querySelector(
      '[data-testid="module-unlock-at-date"] .visible-desktop',
    )
    const mobileElement = container.querySelector(
      '[data-testid="module-unlock-at-date"] .hidden-desktop',
    )

    expect(desktopElement).toBeInTheDocument()
    expect(mobileElement).toBeInTheDocument()

    const desktopText = desktopElement?.textContent
    const mobileText = mobileElement?.textContent
    expect(desktopText).toMatch(`Will unlock ${formattedDate}`)
    expect(mobileText).toMatch(`Unlocked ${formattedDate}`)
  })

  it('returns null when unlockAt is null', () => {
    const {container} = setUp(buildDefaultProps({unlockAt: null}))
    expect(container).toBeEmptyDOMElement()
  })

  it('returns null when unlockAt is in the past', () => {
    const pastDate = moment().subtract(1, 'day').toISOString()
    const {container} = setUp(buildDefaultProps({unlockAt: pastDate}))
    expect(container).toBeEmptyDOMElement()
  })
})
