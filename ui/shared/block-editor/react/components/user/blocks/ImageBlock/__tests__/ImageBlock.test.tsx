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
import {render, waitFor} from '@testing-library/react'
import fetchMock from 'fetch-mock'
import {Editor, Frame} from '@craftjs/core'
import {ImageBlock, type ImageBlockProps} from '..'

const renderBlock = (props: Partial<ImageBlockProps> = {}) => {
  return render(
    <Editor enabled={true} resolver={{ImageBlock}}>
      <Frame>
        <ImageBlock {...props} />
      </Frame>
    </Editor>,
  )
}
describe('ImageBlock', () => {
  beforeEach(() => {
    fetchMock.get('*', 200)
  })
  afterEach(() => {
    fetchMock.reset()
  })

  it('should render with default props', () => {
    const {container} = renderBlock()
    const block = container.querySelector('.image-block.empty')
    expect(block).toBeInTheDocument()
  })

  it('should render with src', () => {
    const {container} = renderBlock({src: 'https://example.com/image.jpg'})
    const img = container.querySelector('img')
    expect(img).toBeInTheDocument()
    expect(img?.getAttribute('src')).toBe('https://example.com/image.jpg')
  })

  describe('sizing', () => {
    it('should render auto width and height with default sizeVariant', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        width: 101,
        height: 201,
      })
      const img = container.querySelector('.image-block')
      expect(img).toHaveStyle({width: 'auto', height: 'auto'})
    })

    it('should render px width and height with pixel sizeVariant', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        sizeVariant: 'pixel',
        width: 101,
        height: 201,
      })
      const img = container.querySelector('.image-block')
      expect(img).toHaveStyle({width: '101px', height: '201px'})
    })

    it('should render % width and px height with "percent" sizeVariant', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        sizeVariant: 'percent',
        width: 101,
        height: 201,
      })
      const img = container.querySelector('.image-block') as HTMLElement
      expect(img).toHaveStyle({width: '101%', height: '201px'})
    })

    it('should render %width and auto height with "percent" sizeVariant and maintainAspectRatio', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        sizeVariant: 'percent',
        width: 101,
        height: 201,
        maintainAspectRatio: true,
      })
      const img = container.querySelector('.image-block') as HTMLElement
      expect(img).toHaveStyle({width: '101%', height: 'auto'})
    })
  })

  describe('constraints', () => {
    it('should render with default cover constraint', () => {
      const {container} = renderBlock({src: 'https://example.com/image.jpg'})
      const img = container.querySelector('img')
      expect(img).toHaveStyle({objectFit: 'cover'})
    })

    it('should render with cover constraint when maintainAspectRatio is true, regardless of constraint prop', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        constraint: 'contain',
        maintainAspectRatio: true,
      })
      const img = container.querySelector('img')
      expect(img).toHaveStyle({objectFit: 'cover'})
    })

    it('should render with contain constraint', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        constraint: 'contain',
        maintainAspectRatio: false,
      })
      const img = container.querySelector('img')
      expect(img).toHaveStyle({objectFit: 'contain'})
    })
  })

  describe('svg handling', () => {
    beforeEach(() => {
      fetchMock.reset()
      fetchMock.get('some-image.svg', {
        status: 201,
        body: '<svg></svg>',
        headers: {'Content-type': 'image/svg+xml'},
      })
    })

    it('renders the svg inline', async () => {
      const {container} = renderBlock({
        src: 'some-image.svg',
      })
      const block = container.querySelector('.image-block') as HTMLElement
      expect(block).toBeInTheDocument()
      await waitFor(() => {
        expect(block?.querySelector('img')).not.toBeInTheDocument()
        expect(block.querySelector('svg')).toBeInTheDocument()
      })
      expect(block.querySelector('svg')?.outerHTML).toEqual('<svg></svg>')
    })
  })
})
