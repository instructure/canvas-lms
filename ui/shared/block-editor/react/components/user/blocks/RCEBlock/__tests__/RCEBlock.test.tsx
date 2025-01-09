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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {Editor, Frame, useNode} from '@craftjs/core'
import {RCEBlock, type RCEBlockProps} from '..'

let props: Partial<RCEBlockProps>

const mockSetProp = jest.fn((callback: (props: Record<string, any>) => void) => {
  callback(props)
})

let isSelected = false

jest.mock('@craftjs/core', () => {
  const originalModule = jest.requireActual('@craftjs/core')
  return {
    ...originalModule,
    useNode: jest.fn(_node => {
      return {
        actions: {setProp: mockSetProp},
        connectors: {
          connect: jest.fn(),
          drag: jest.fn(),
        },
        id: 'xyzzy',
        selected: isSelected,
      }
    }),
  }
})

const renderBlock = (enabled: boolean, props: Partial<RCEBlockProps> = {}) => {
  return render(
    <div>
      <div role="alert" id="flash_screenreader_holder" aria-live="polite" />
      <Editor enabled={enabled} resolver={{RCEBlock}}>
        <Frame>
          <RCEBlock {...props} />
        </Frame>
      </Editor>
    </div>,
  )
}

describe('RCEBlock', () => {
  beforeEach(() => {
    isSelected = false
    props = {...RCEBlock.craft.defaultProps} as Partial<RCEBlockProps>
  })

  describe('in an enabled Editor', () => {
    describe('when unselected', () => {
      it('should render an empty div with default props', () => {
        const {container} = renderBlock(true)
        const block = container.querySelector('.rce-text-block') as HTMLElement
        expect(block).toBeInTheDocument()
        expect(block).toBeEmptyDOMElement()
      })

      it('should render a div with text', () => {
        const {container} = renderBlock(true, {text: 'This is text'})
        const block = container.querySelector('.rce-text-block') as HTMLElement
        expect(block).toHaveTextContent('This is text')
      })
    })

    describe('when selected', () => {
      it('should render the rce with default props', async () => {
        isSelected = true
        const {container} = renderBlock(true)
        await waitFor(() => {
          expect(container.querySelector('.rce-wrapper')).toBeInTheDocument()
        })
      })

      it('should render the rce with the given text', async () => {
        isSelected = true
        const {container} = renderBlock(true, {text: 'This is text'})
        await waitFor(() => {
          expect(container.querySelector('.rce-wrapper')).toHaveTextContent('This is text')
        })
        const rcetextarea = container.querySelector(
          `#rceblock_text-${props.id}`,
        ) as HTMLTextAreaElement
        expect(rcetextarea).toHaveValue('This is text')
      })
    })
  })

  describe('in a disabled Editor', () => {
    it('should render a div with the text prop value', () => {
      const {container} = renderBlock(false, {text: 'This is text'})
      const block = container.querySelector('.rce-text-block') as HTMLElement
      expect(block).toHaveTextContent('This is text')
    })
  })
})
