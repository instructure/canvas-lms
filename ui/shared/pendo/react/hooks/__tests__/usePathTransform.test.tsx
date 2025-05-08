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
import {usePathTransform} from '@canvas/pendo/react/hooks/usePathTransform'

describe('usePathTransform', () => {
  beforeEach(() => {
    window.history.pushState({}, '', '/discussion_topics/12345')
    jest.clearAllMocks()
  })

  function TestComponent({whenPendoReady, searchValue, replaceValue, shouldTransform}: any) {
    usePathTransform(whenPendoReady, searchValue, replaceValue, shouldTransform)
    return null
  }

  it('does not throw if whenPendoReady is null', () => {
    expect(() => {
      render(
        <TestComponent
          whenPendoReady={null}
          searchValue="/discussion"
          replaceValue="/announcements"
          shouldTransform={true}
        />,
      )
    }).not.toThrow()
  })

  it('calls pendo.location.addTransforms with transformed pathname when shouldTransform is true', async () => {
    const mockAddTransforms = jest.fn()
    const pendoMock = {
      location: {
        addTransforms: mockAddTransforms,
      },
    }

    const whenPendoReady = Promise.resolve(pendoMock)

    render(
      <TestComponent
        whenPendoReady={whenPendoReady}
        searchValue="discussion_topics"
        replaceValue="announcements"
        shouldTransform={true}
      />,
    )

    await whenPendoReady

    expect(mockAddTransforms).toHaveBeenCalledWith([
      {
        attr: 'pathname',
        action: 'Replace',
        data: '/announcements/12345',
      },
    ])
  })

  it('does nothing if shouldTransform is false', async () => {
    const mockAddTransforms = jest.fn()
    const pendoMock = {
      location: {
        addTransforms: mockAddTransforms,
      },
    }

    const whenPendoReady = Promise.resolve(pendoMock)

    render(
      <TestComponent
        whenPendoReady={whenPendoReady}
        searchValue="/discussion"
        replaceValue="/announcements"
        shouldTransform={false}
      />,
    )

    await whenPendoReady

    expect(mockAddTransforms).not.toHaveBeenCalled()
  })

  it('does nothing if shouldTransform is undefined', async () => {
    const mockAddTransforms = jest.fn()
    const pendoMock = {
      location: {
        addTransforms: mockAddTransforms,
      },
    }

    const whenPendoReady = Promise.resolve(pendoMock)

    render(
      <TestComponent
        whenPendoReady={whenPendoReady}
        searchValue="/discussion"
        replaceValue="/announcements"
      />,
    )

    await whenPendoReady

    expect(mockAddTransforms).not.toHaveBeenCalled()
  })
})
