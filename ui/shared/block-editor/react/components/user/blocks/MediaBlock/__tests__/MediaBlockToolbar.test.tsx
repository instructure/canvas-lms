/*
 * Copyright (C) 2024 - present Instructure, Inc.
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
import {fireEvent, render, screen} from '@testing-library/react'
import {MediaBlock, type MediaBlockProps} from '..'
import {MediaBlockToolbar} from '../MediaBlockToolbar'

let props: Partial<MediaBlockProps>

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useNode: jest.fn(_node => {
      return {
        props,
        actions: {setProp: mockSetProp},
        node: {
          dom: document.createElement('iframe'),
        },
        domnode: document.createElement('iframe'),
      }
    }),
  }
})

describe('MediaBlockToolbar', () => {
  beforeEach(() => {
    props = {...(MediaBlock.craft.defaultProps as Partial<MediaBlockProps>)}
  })

  it('should render the "Add Media button"', () => {
    render(<MediaBlockToolbar />)
    expect(screen.getByText('Add Media')).toBeInTheDocument()
  })

  it.skip('checks the right constraint', async () => {
    render(<MediaBlockToolbar />)

    const btn = screen.getByText('Constraint').closest('button') as HTMLButtonElement
    fireEvent.click(btn)

    const coverMenuItem = screen.getByText('Cover')
    const containMenuItem = screen.getByText('Contain')
    const aspectRatioMenuItem = screen.getByText('Match Aspect Ratio')

    expect(coverMenuItem).toBeInTheDocument()
    expect(containMenuItem).toBeInTheDocument()
    expect(aspectRatioMenuItem).toBeInTheDocument()

    const li = coverMenuItem.closest('li') as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()
  })

  it.skip('changes the constraint prop', async () => {
    render(<MediaBlockToolbar />)

    const btn = screen.getByText('Constraint').closest('button') as HTMLButtonElement
    fireEvent.click(btn)

    const containMenuItem = screen.getByText('Contain')
    fireEvent.click(containMenuItem)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.constraint).toBe('contain')
    expect(props.maintainAspectRatio).toBe(false)
  })

  it.skip('changes the maintainAspectRatio prop', async () => {
    props.maintainAspectRatio = false
    render(<MediaBlockToolbar />)

    const btn = screen.getByText('Constraint').closest('button') as HTMLButtonElement
    fireEvent.click(btn)

    const coverMenuItem = screen.getByText('Cover')
    let li = coverMenuItem.closest('li') as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).toBeInTheDocument()

    const aspectRatioMenuItem = screen.getByText('Match Aspect Ratio')
    li = aspectRatioMenuItem.closest('li') as HTMLLIElement
    expect(li.querySelector('svg[name="IconCheck"]')).not.toBeInTheDocument()

    fireEvent.click(aspectRatioMenuItem)

    expect(mockSetProp).toHaveBeenCalled()
    expect(props.maintainAspectRatio).toBe(true)
    expect(props.constraint).toBe('cover')
  })

  it.skip('changes the image size prop', async () => {
    props.width = 117
    props.height = 217
    render(<MediaBlockToolbar />)

    const btn = screen.getByText('Media Size').closest('button') as HTMLButtonElement
    fireEvent.click(btn)

    expect(screen.getByText('Auto')).toBeInTheDocument()
    expect(screen.getByText('Fixed size')).toBeInTheDocument()
    expect(screen.getByText('Percent size')).toBeInTheDocument()
    expect(
      screen.getByText('Auto').closest('li')?.querySelector('svg[name="IconCheck"')
    ).toBeInTheDocument()

    fireEvent.click(screen.getByText('Fixed size'))
    expect(props.sizeVariant).toBe('pixel')
  })
})
