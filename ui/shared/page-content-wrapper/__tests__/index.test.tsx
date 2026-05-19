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
import {_resetPageContentWrapper, registerPageContentWrapper, usePageContentWrapper} from '..'

function Probe() {
  const Wrapper = usePageContentWrapper()
  if (!Wrapper) return <span data-testid="probe-empty" />
  const fakeContent = document.createElement('div')
  return <Wrapper pageContent={fakeContent} />
}

describe('page-content-wrapper', () => {
  beforeEach(() => {
    _resetPageContentWrapper()
  })

  it('returns undefined when no wrapper is registered', () => {
    render(<Probe />)
    expect(screen.getByTestId('probe-empty')).toBeInTheDocument()
  })

  it('returns the registered wrapper after registration', () => {
    function Wrapper() {
      return <span data-testid="from-wrapper" />
    }
    registerPageContentWrapper(Wrapper)
    render(<Probe />)
    expect(screen.getByTestId('from-wrapper')).toBeInTheDocument()
  })

  it('updates consumers when a wrapper is registered after they mounted', () => {
    render(<Probe />)
    expect(screen.getByTestId('probe-empty')).toBeInTheDocument()

    function Wrapper() {
      return <span data-testid="late-wrapper" />
    }
    act(() => {
      registerPageContentWrapper(Wrapper)
    })
    expect(screen.getByTestId('late-wrapper')).toBeInTheDocument()
  })
})
