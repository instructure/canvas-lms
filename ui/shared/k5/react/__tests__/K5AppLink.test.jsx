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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import K5AppLink from '../K5AppLink'

describe('K5AppLink', () => {
  const getProps = (overrides = {}) => ({
    app: {
      id: '1',
      courses: [
        {
          id: '1',
          name: 'Physics',
        },
        {
          id: '2',
          name: 'English',
        },
      ],
      title: 'YouTube',
      icon: '/youtubeicon.png',
      ...overrides,
    },
  })

  let assign

  beforeAll(() => {
    assign = window.location.assign
    Object.defineProperty(window, 'location', {
      value: {assign: jest.fn()},
    })
  })

  afterAll(() => {
    Object.defineProperty(window, 'location', {
      value: {assign},
    })
  })

  it('renders app name', () => {
    const {getByText} = render(<K5AppLink {...getProps()} />)
    expect(getByText('YouTube')).toBeInTheDocument()
  })

  it('renders app icon and alt text if provided', () => {
    const {getByTestId} = render(<K5AppLink {...getProps()} />)
    const image = getByTestId('renderedIcon')
    expect(image).toBeInTheDocument()
    expect(image.src).toContain('/youtubeicon.png')
  })

  it('renders a default IconLti icon if no icon provided', () => {
    const {getByTestId} = render(<K5AppLink {...getProps({icon: null})} />)
    const svg = getByTestId('defaultIcon')
    expect(svg).toBeInTheDocument()
    expect(svg.getAttribute('name')).toBe('IconLti')
  })

  it('opens tool directly if installed in only one course', () => {
    const overrides = {
      courses: [
        {
          id: '14',
          name: 'Science',
        },
      ],
    }
    const {getByText} = render(<K5AppLink {...getProps(overrides)} />)
    const button = getByText('YouTube')
    fireEvent.click(button)
    expect(window.location.assign).toHaveBeenCalledWith('/courses/14/external_tools/1')
  })

  it('adds display borderless to URL if windowTarget present in the app', () => {
    const overrides = {
      courses: [
        {
          id: '14',
          name: 'Science',
        },
      ],
      windowTarget: '_blank',
    }
    const {getByText} = render(<K5AppLink {...getProps(overrides)} />)
    const button = getByText('YouTube')
    Object.defineProperty(window, 'open', {value: jest.fn()})
    fireEvent.click(button)
    expect(window.open).toHaveBeenCalledWith(
      '/courses/14/external_tools/1?display=borderless',
      '_blank'
    )
  })

  it('opens modal if installed in more than one course', () => {
    const {getByText} = render(<K5AppLink {...getProps()} />)
    const button = getByText('YouTube')
    fireEvent.click(button)
    expect(getByText('Choose a Course')).toBeInTheDocument()
  })

  it('includes links to launch tools in the modal', () => {
    const {getByText} = render(<K5AppLink {...getProps()} />)
    const button = getByText('YouTube')
    fireEvent.click(button)
    const physicsTool = getByText('Physics')
    const englishTool = getByText('English')
    expect(physicsTool.href).toContain('/courses/1/external_tools/1')
    expect(englishTool.href).toContain('/courses/2/external_tools/1')
  })

  it('includes display borderless in links to launch tools in the modal if windowTarget is present', () => {
    const overrides = {
      windowTarget: '_blank',
    }
    const {getByText} = render(<K5AppLink {...getProps(overrides)} />)
    const button = getByText('YouTube')
    fireEvent.click(button)
    const physicsTool = getByText('Physics')
    const englishTool = getByText('English')
    expect(physicsTool.href).toContain(encodeURI('/courses/1/external_tools/1?display=borderless'))
    expect(physicsTool.target).toContain('_blank')
    expect(englishTool.href).toContain(encodeURI('/courses/2/external_tools/1?display=borderless'))
    expect(englishTool.target).toContain('_blank')
  })
})
