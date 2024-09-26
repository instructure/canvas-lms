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
import {fireEvent, render, screen, waitFor} from '@testing-library/react'
import {getByText as domGetByText} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import BlockEditor from '../../../BlockEditor'
import {blank_section_with_button_and_heading} from '../../../__tests__/test-content'
import {LATEST_BLOCK_DATA_VERSION} from '../../../utils/transformations'

const user = userEvent.setup()

function renderEditor(props = {}) {
  const container = document.createElement('div')
  container.id = 'drawer-layout-content'
  container.scrollTo = () => {}
  document.body.appendChild(container)

  return render(
    <BlockEditor
      enableResizer={false} // jsdom doesn't render enough for BlockResizer to work
      container={container}
      content={{version: LATEST_BLOCK_DATA_VERSION, blocks: blank_section_with_button_and_heading}}
      onCancel={() => {}}
      {...props}
    />,
    {container}
  )
}

const getPage = () => document.querySelector('.block.page-block') as HTMLElement
const getButton = () => document.querySelector('[data-testid="button-block"]') as HTMLElement
const getHeading = () => document.querySelector('.block.heading-block') as HTMLElement
const getBlankSection = () => document.querySelector('.section.blank-section') as HTMLElement
const getBlockToolbar = () => document.querySelector('.block-toolbar') as HTMLElement
const getSectionMenu = () => document.querySelector('.section-menu') as HTMLElement
const getBlockTag = () => document.querySelector('.block-tag') as HTMLElement

describe('BlockEditor', () => {
  beforeAll(() => {
    window.alert = jest.fn()
  })

  it('renders', () => {
    renderEditor()

    expect(getPage()).toBeInTheDocument()
    expect(getBlankSection()).toBeInTheDocument()
    expect(getButton()).toBeInTheDocument()
    expect(getHeading()).toBeInTheDocument()

    // TODO: why is it in the dom now, but not in canvas?
    // expect(getSectionMenu()).not.toBeInTheDocument()
    // expect(getBlockToolbar()).not.toBeInTheDocument()
    expect(getBlockTag()).not.toBeInTheDocument()
  })

  it.skip('shows the section menu and toolbar on first click', async () => {
    renderEditor()
    expect(getSectionMenu()).toBeInTheDocument()
    expect(getBlockToolbar()).toBeInTheDocument()
    expect(domGetByText(getBlockToolbar(), 'Blank Section')).toBeInTheDocument()

    const buttonBlock = getButton()
    await user.click(buttonBlock)
    await waitFor(() => {
      expect(getSectionMenu()).toBeInTheDocument()
      expect(domGetByText(getBlockToolbar(), 'Blank Section')).toBeInTheDocument()
    })
  })

  it.skip('shows the block toolbar on second click', async () => {
    renderEditor()
    expect(getSectionMenu()).toBeInTheDocument()
    expect(getBlockToolbar()).toBeInTheDocument()
    expect(domGetByText(getBlockToolbar(), 'Blank Section')).toBeInTheDocument()

    const buttonBlock = getButton()
    await user.click(buttonBlock)
    await user.click(buttonBlock)
    await waitFor(() => {
      expect(getSectionMenu()).not.toBeInTheDocument()
      expect(domGetByText(getBlockToolbar(), 'Button')).toBeInTheDocument()
    })
    const toolbar = getBlockToolbar()
    expect(domGetByText(toolbar, 'Drag to move')).toBeInTheDocument()
    expect(domGetByText(toolbar, 'Go to parent')).toBeInTheDocument()
    expect(domGetByText(toolbar, 'Delete')).toBeInTheDocument()
    expect(domGetByText(toolbar, 'Link')).toBeInTheDocument()
    expect(domGetByText(toolbar, 'Size')).toBeInTheDocument()
    expect(domGetByText(toolbar, 'Style')).toBeInTheDocument()
    expect(domGetByText(toolbar, 'Color')).toBeInTheDocument()
    expect(domGetByText(toolbar, 'Select Icon')).toBeInTheDocument()
  })

  it('switches to the new block on cick once section has been selected', async () => {
    renderEditor()
    const buttonBlock = getButton()
    await user.click(buttonBlock)
    await user.click(buttonBlock)
    await waitFor(() => {
      expect(domGetByText(getBlockToolbar(), 'Button')).toBeInTheDocument()
    })
    const iconBlock = getHeading()
    await user.click(iconBlock)
    await waitFor(() => {
      expect(domGetByText(getBlockToolbar(), 'Heading')).toBeInTheDocument()
    })
    expect(domGetByText(getBlockToolbar(), 'Level')).toBeInTheDocument()
  })

  it('selects the page on ESC', async () => {
    renderEditor()
    const buttonBlock = getButton()
    // await user.click(buttonBlock)
    await user.click(buttonBlock)
    await waitFor(() => {
      expect(domGetByText(getBlockToolbar(), 'Button')).toBeInTheDocument()
    })
    fireEvent.keyDown(getPage(), {key: 'Escape', code: 'Escape'})
    await waitFor(() => {
      expect(domGetByText(getBlockToolbar(), 'Page')).toBeInTheDocument()
    })
    expect(getSectionMenu()).not.toBeInTheDocument()
  })

  it('selects the parent section on clicking up button', async () => {
    renderEditor()
    const buttonBlock = getButton()
    await user.click(buttonBlock)
    await user.click(buttonBlock)
    await waitFor(() => {
      expect(domGetByText(getBlockToolbar(), 'Button')).toBeInTheDocument()
    })
    expect(getSectionMenu()).not.toBeInTheDocument()

    const upButton = domGetByText(getBlockToolbar(), 'Go to parent').closest(
      'button'
    ) as HTMLButtonElement
    await user.click(upButton)
    await waitFor(() => {
      expect(domGetByText(getBlockToolbar(), 'Blank Section')).toBeInTheDocument()
    })
    expect(getSectionMenu()).toBeInTheDocument()
  })

  it('deletes the block on clicking delete button', async () => {
    renderEditor()
    const buttonBlock = getButton()
    await user.click(buttonBlock)
    await user.click(buttonBlock)
    await waitFor(() => {
      expect(domGetByText(getBlockToolbar(), 'Button')).toBeInTheDocument()
    })
    expect(getSectionMenu()).not.toBeInTheDocument()

    const deleteButton = domGetByText(getBlockToolbar(), 'Delete').closest(
      'button'
    ) as HTMLButtonElement
    await user.click(deleteButton)
    await waitFor(() => {
      expect(getBlockToolbar()).not.toBeInTheDocument()
      expect(getButton()).not.toBeInTheDocument()
    })
    expect(getHeading()).toBeInTheDocument()
  })

  it('chnages the rendered dom when changing props via the toolbar', async () => {
    renderEditor()
    const headingBlock = getHeading()
    expect(headingBlock.tagName).toBe('H2')

    await user.click(headingBlock)
    await user.click(headingBlock)
    await waitFor(() => {
      expect(domGetByText(getBlockToolbar(), 'Heading')).toBeInTheDocument()
    })
    const levelButton = domGetByText(getBlockToolbar(), 'Level').closest(
      'button'
    ) as HTMLButtonElement
    await user.click(levelButton)
    await waitFor(() => {
      expect(screen.getByText('Heading 3')).toBeInTheDocument()
    })
    await user.click(screen.getByText('Heading 3'))

    expect(getHeading().tagName).toBe('H3')
  })
})
