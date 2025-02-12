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
import {render, screen, waitFor} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {Editor, Frame} from '@craftjs/core'
import {HeadingBlock, type HeadingBlockProps} from '..'

const renderBlock = (enabled: boolean, props: Partial<HeadingBlockProps> = {}) => {
  const user = userEvent.setup()
  const result = render(
    <>
      <div id="another-element" tabIndex={-1} data-testid="another-element">Another Element</div>
      <Editor enabled={enabled} resolver={{HeadingBlock}}>
        <Frame>
          <HeadingBlock text="A Heading" {...props} />
        </Frame>
      </Editor>
    </>,
  )
  return {
    ...result,
    user,
  }
}

describe('HeadingBlock', () => {
  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('in an enabled Editor', () => {
    it('should render editable version with default props', async () => {
      const {container} = renderBlock(true)
      const heading = container.querySelector('h2')
      expect(heading).toBeInTheDocument()
      expect(screen.getByText('A Heading')).toBeInTheDocument()

      await waitFor(() => {
        expect(heading).toHaveAttribute('contenteditable', 'true')
        expect(heading).toHaveAttribute('data-placeholder', 'Heading 2')
      })
    })

    it('should stop being editable on blur', async () => {
      const {container, user} = renderBlock(true)
      const heading = container.querySelector('h2') as HTMLElement
      const otherElement = screen.getByTestId('another-element')

      // Focus the heading
      await user.click(heading)
      await waitFor(() => {
        expect(heading).toHaveAttribute('contenteditable', 'true')
      })

      // Move focus away
      await user.click(otherElement)
      await waitFor(() => {
        expect(heading).toHaveAttribute('contenteditable', 'false')
      })
    })

    it('should render active editable version on click', async () => {
      const {container, user} = renderBlock(true)
      const heading = container.querySelector('h2') as HTMLElement
      const otherElement = screen.getByTestId('another-element')

      // First focus and blur to get to non-editable state
      await user.click(heading)
      await user.click(otherElement)
      await waitFor(() => {
        expect(heading).toHaveAttribute('contenteditable', 'false')
      })

      // Then click to make editable again
      await user.click(heading)
      await waitFor(() => {
        expect(heading).toHaveAttribute('contenteditable', 'true')
      })
    })

    it('respects the level prop', async () => {
      const {container} = renderBlock(true, {level: 'h3'})
      const heading = container.querySelector('h3')
      expect(heading).toBeInTheDocument()
    })
  })

  describe('in a disabled Editor', () => {
    it('should render non-editable version with default props', async () => {
      const {container} = renderBlock(false)
      
      expect(screen.getByText('A Heading')).toBeInTheDocument()
      expect(container.querySelector('h2')).toBeInTheDocument()
      expect(container.querySelector('[contenteditable]')).toBeNull()
    })

    it('respects the level prop', async () => {
      const {container} = renderBlock(false, {level: 'h3'})
      expect(container.querySelector('h3')).toBeInTheDocument()
    })
  })
})
