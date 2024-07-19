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
import userEvent, {PointerEventsCheckLevel} from '@testing-library/user-event'
import {Editor, Frame} from '@craftjs/core'
import {NoSections} from '../../../common/NoSections'
import {TabsBlock, TabBlock, type TabsBlockProps} from '..'

const user = userEvent.setup({pointerEventsCheck: PointerEventsCheckLevel.Never})

const renderBlock = (enabled: boolean, props: Partial<TabsBlockProps> = {}) => {
  return render(
    <Editor enabled={enabled} resolver={{TabsBlock, TabBlock, NoSections}}>
      <Frame>
        <TabsBlock {...props} />
      </Frame>
    </Editor>
  )
}

describe('TabsBlock', () => {
  it('should render with default props', () => {
    const {container, getByText} = renderBlock(true)
    expect(getByText('Tab 1')).toBeInTheDocument()
    expect(getByText('Tab 2')).toBeInTheDocument()

    // eslint-disable-next-line no-undef
    const contentEditables = container.querySelectorAll('[contenteditable]') as NodeListOf<Element>
    expect(contentEditables.length).toBe(2)
  })

  it('should render with custom tabs', () => {
    const {getByText} = renderBlock(true, {
      tabs: [
        {id: '1', title: 'Custom Tab 1'},
        {id: '2', title: 'Custom Tab 2'},
      ],
    })
    expect(getByText('Custom Tab 1')).toBeInTheDocument()
    expect(getByText('Custom Tab 2')).toBeInTheDocument()
  })

  it('should switch tabs on click', () => {
    const {container, getByText} = renderBlock(true)
    expect(getByText('Tab 1')).toBeInTheDocument()
    expect(getByText('Tab 2')).toBeInTheDocument()

    const tabs = container.querySelectorAll('[role="tab"]')
    expect(tabs.length).toBe(2)
    expect(tabs[0]).toHaveAttribute('aria-selected', 'true')
    expect(tabs[1]).not.toHaveAttribute('aria-selected')
    ;(tabs[1] as HTMLElement).click()
    const tabs2 = container.querySelectorAll('[role="tab"]')
    expect(tabs.length).toBe(2)

    expect(tabs2[0]).not.toHaveAttribute('aria-selected')
    expect(tabs2[1]).toHaveAttribute('aria-selected', 'true')
  })

  it('makes tab labels editable', () => {
    const {container, getByText} = renderBlock(true)
    expect(getByText('Tab 1')).toBeInTheDocument()
    expect(getByText('Tab 2')).toBeInTheDocument()

    const tabs = container.querySelectorAll('[role="tab"] [contenteditable]')
    expect(tabs.length).toBe(2)
    expect(tabs[0]).toHaveAttribute('contenteditable', 'true')
    expect(tabs[1]).toHaveAttribute('contenteditable', 'true')
  })

  it('should delete tab on clicking delete button', async () => {
    const {queryByText, getByText, getAllByText} = renderBlock(true)
    expect(getByText('Tab 1')).toBeInTheDocument()
    expect(getByText('Tab 2')).toBeInTheDocument()

    const deleteButtons = getAllByText('Delete Tab')
    expect(deleteButtons.length).toBe(2)
    const b0 = deleteButtons[0].closest('button') as HTMLButtonElement
    user.click(b0)
    await waitFor(() => {
      expect(getByText('Tab 2')).toBeInTheDocument()
      expect(queryByText('Tab 1')).toBeNull()
    })
  })
})
