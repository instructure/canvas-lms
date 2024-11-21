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
import {render} from '@testing-library/react'
import {Editor, Frame} from '@craftjs/core'
import {MediaBlock, type MediaBlockProps} from '..'

const renderBlock = (props: Partial<MediaBlockProps> = {}) => {
  return render(
    <Editor enabled={true} resolver={{MediaBlock}}>
      <Frame>
        <MediaBlock {...props} />
      </Frame>
    </Editor>
  )
}
describe('MediaBlock', () => {
  it('render', () => {
    const {container} = renderBlock()
    const block = container.querySelector('.media-block.empty')
    expect(block).toBeInTheDocument()
  })

  it.skip('should render with src', () => {
    const {container} = renderBlock({src: 'https://example.com/video.mp4'})
    const iframe = container.querySelector('iframe')
    expect(iframe).toBeInTheDocument()
    expect(iframe?.getAttribute('src')).toBe('https://example.com/video.mp4')
  })

  describe('sizing', () => {
    it.skip('should render auto width and height with default sizeVariant', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        width: 101,
        height: 201,
      })
      const iframe = container.querySelector('.media-block')
      expect(iframe).toHaveStyle({width: 'auto', height: 'auto'})
    })

    it.skip('should render px width and height with pixel sizeVariant', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        sizeVariant: 'pixel',
        width: 101,
        height: 201,
      })
      const iframe = container.querySelector('.media-block')
      expect(iframe).toHaveStyle({width: '101px', height: '201px'})
    })

    it.skip('should render % width and px height with "percent" sizeVariant', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        sizeVariant: 'percent',
        width: 101,
        height: 201,
      })
      const iframe = container.querySelector('.media-block') as HTMLElement
      expect(iframe).toHaveStyle({height: '201%', width: '101%'})
    })

    it.skip('should render %width and auto height with "percent" sizeVariant and maintainAspectRatio', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        sizeVariant: 'percent',
        width: 101,
        height: 201,
        maintainAspectRatio: true,
      })
      const iframe = container.querySelector('.media-block') as HTMLElement
      expect(iframe).toHaveStyle({height: 'auto'})
      expect(iframe.style.width).toMatch(/%$/)
    })
  })

  describe('constraints', () => {
    it.skip('should render with default cover constraint', () => {
      const {container} = renderBlock({src: 'https://example.com/image.jpg'})
      const iframe = container.querySelector('iframe')
      expect(iframe).toHaveStyle({objectFit: 'cover'})
    })

    it.skip('should render with cover constraint when maintainAspectRatio is true, regardless of constraint prop', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        constraint: 'contain',
        maintainAspectRatio: true,
      })
      const iframe = container.querySelector('iframe')
      expect(iframe).toHaveStyle({objectFit: 'cover'})
    })

    it.skip('should render with contain constraint', () => {
      const {container} = renderBlock({
        src: 'https://example.com/image.jpg',
        constraint: 'contain',
        maintainAspectRatio: false,
      })
      const iframe = container.querySelector('iframe')
      expect(iframe).toHaveStyle({objectFit: 'contain'})
    })
  })
})
