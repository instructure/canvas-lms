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
import {render, getNodeText, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Editor, Frame} from '@craftjs/core'
import {TextBlock, type TextBlockProps} from '..'

const renderBlock = (enabled: boolean, props: Partial<TextBlockProps> = {}) => {
  return render(
    <>
      <div id="another-element" tabIndex={-1} />
      <Editor enabled={enabled} resolver={{TextBlock}}>
        <Frame>
          <TextBlock {...props} />
        </Frame>
      </Editor>
    </>,
  )
}

describe('TextBlock', () => {
  describe('in an enabled Editor', () => {
    it('should render editable version with default props', () => {
      const {container, getByText} = renderBlock(true, {text: 'some text'})
      expect(getByText('some text')).toBeInTheDocument()

      const contentEditable = container.querySelector('[contenteditable]') as HTMLElement
      expect(contentEditable).toBeInTheDocument()
      expect(contentEditable.getAttribute('data-placeholder')).toBe('Type something')
      expect(contentEditable.getAttribute('contenteditable')).toBe('true')

      const block = container.querySelector('.text-block')
      expect(block).toHaveStyle({
        fontSize: '12pt',
        textAlign: 'initial',
        color: 'var(--ic-brand-font-color-dark)',
      })
    })

    it('should stop being editable on blur', async () => {
      const {container} = renderBlock(true, {text: 'some text'})
      const contentEditable = container.querySelector('[contenteditable]') as HTMLElement
      ;(document.querySelector('.text-block') as HTMLElement).focus()
      expect(contentEditable.getAttribute('contenteditable')).toBe('true')

      document.getElementById('another-element')?.focus()
      expect(contentEditable.getAttribute('contenteditable')).toBe('false')
    })

    it('should render active editable version on click', async () => {
      const {container} = renderBlock(true, {text: 'some text'})
      const contentEditable = container.querySelector('[contenteditable]') as HTMLElement
      ;(document.querySelector('.text-block') as HTMLElement).focus()
      document.getElementById('another-element')?.focus()
      expect(contentEditable.getAttribute('contenteditable')).toBe('false')

      await userEvent.click(contentEditable)
      expect(contentEditable.getAttribute('contenteditable')).toBe('true')
    })

    it('respects the fontSize prop', () => {
      const {container} = renderBlock(true, {
        text: 'some text',
        fontSize: '24pt',
      })
      const block = container.querySelector('.text-block')
      expect(block).toHaveStyle('fontSize: 24pt')
    })

    it('respects the textAlign prop', () => {
      const {container} = renderBlock(true, {
        text: 'some text',
        textAlign: 'center',
      })
      const block = container.querySelector('.text-block')
      expect(block).toHaveStyle('textAlign: center')
    })

    it('respects the color prop', () => {
      const {container} = renderBlock(true, {
        text: 'some text',
        color: 'red',
      })
      const block = container.querySelector('.text-block')
      expect(block).toHaveStyle({color: 'rgb(255, 0, 0)'})
    })
  })

  describe('in a disabled Editor', () => {
    it('should render non-editable version with default props', () => {
      const {container, getByText} = renderBlock(false, {text: 'some text'})
      expect(getByText('some text')).toBeInTheDocument()

      const contentEditable = container.querySelector('[contenteditable]')
      expect(contentEditable).toBeNull()

      const block = container.querySelector('.text-block')
      expect(block).toHaveStyle({
        fontSize: '12pt',
        textAlign: 'initial',
        color: 'var(--ic-brand-font-color-dark)',
      })
    })

    it('respects given props', () => {
      const {container} = renderBlock(false, {
        text: 'some text',
        fontSize: '24pt',
        textAlign: 'center',
        color: 'red',
      })
      const block = container.querySelector('.text-block') as HTMLElement
      expect(getNodeText(block)).toBe('some text')
      expect(block).toHaveStyle({
        fontSize: '24pt',
        textAlign: 'center',
        color: 'rgb(255, 0, 0)',
      })
    })
  })
})
