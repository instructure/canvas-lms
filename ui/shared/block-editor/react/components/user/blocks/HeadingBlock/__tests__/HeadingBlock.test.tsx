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
import userEvent from '@testing-library/user-event'
import {Editor, Frame} from '@craftjs/core'
import {HeadingBlock, type HeadingBlockProps} from '..'

const renderBlock = (enabled: boolean, props: Partial<HeadingBlockProps> = {}) => {
  return render(
    <>
      <div id="another-element" tabIndex={-1} />
      <Editor enabled={enabled} resolver={{HeadingBlock}}>
        <Frame>
          <HeadingBlock text="A Heading" {...props} />
        </Frame>
      </Editor>
    </>
  )
}

describe('HeadingBlock', () => {
  describe('in an enabled Editor', () => {
    it('should render editable version with default props', () => {
      const {container, getByText} = renderBlock(true)
      expect(getByText('A Heading')).toBeInTheDocument()

      const heading = container.querySelector('h2') as HTMLElement
      expect(heading).toBeInTheDocument()
      expect(heading.getAttribute('contenteditable')).toBe('true')
      expect(heading.getAttribute('data-placeholder')).toBe('Heading 2')
    })

    it('should stop being editaaable on blur', async () => {
      const {container} = renderBlock(true)
      const heading = container.querySelector('h2') as HTMLElement
      heading.focus()
      expect(heading.getAttribute('contenteditable')).toBe('true')

      document.getElementById('another-element')?.focus()
      expect(heading.getAttribute('contenteditable')).toBe('false')
    })

    it('should render active editable version on click', async () => {
      const {container} = renderBlock(true)
      const heading = container.querySelector('h2') as HTMLElement
      heading.focus()
      document.getElementById('another-element')?.focus()
      expect(heading.getAttribute('contenteditable')).toBe('false')

      await userEvent.click(heading)
      expect(heading.getAttribute('contenteditable')).toBe('true')
    })

    it('respects the level prop', () => {
      const {container} = renderBlock(true, {level: 'h3'})
      const heading = container.querySelector('h3')
      expect(heading).toBeInTheDocument()
    })
  })

  describe('in a disabled Editor', () => {
    it('should render non-editable version with default props', () => {
      const {container, getByText} = renderBlock(false)
      expect(getByText('A Heading')).toBeInTheDocument()

      const heading = container.querySelector('h2')
      expect(heading).toBeInTheDocument()

      const contentEditable = container.querySelector('[contenteditable]')
      expect(contentEditable).toBeNull()
    })

    it('respects the level prop', () => {
      const {container} = renderBlock(false, {level: 'h3'})
      const heading = container.querySelector('h3')
      expect(heading).toBeInTheDocument()
    })
  })
})
