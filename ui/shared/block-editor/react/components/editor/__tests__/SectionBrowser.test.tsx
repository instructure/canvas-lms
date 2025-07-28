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

// TODO: the current implementation of SectionBrowser was done quickly
//       for the demo and will change as designs evolve. There are only
//       a couple rudimentary tests for now.

import React from 'react'
import {Editor, Frame} from '@craftjs/core'

import {fireEvent, render as testRender, screen} from '@testing-library/react'
import {getByText} from '@testing-library/dom'
import userEvent from '@testing-library/user-event'
import {SectionBrowser, type SectionBrowserProps} from '../SectionBrowser'
import type {AddSectionPlacement, RenderNodeProps} from '../types'
import {BlankSection} from '../../user/sections/BlankSection'
import {NoSections} from '../../user/common'

const user = userEvent.setup()

const defaultProps = {
  open: true,
  where: 'append' as AddSectionPlacement,
  onClose: () => {},
}

const renderComponent = (props: Partial<SectionBrowserProps> = {}) => {
  const renderNode = ({render}: RenderNodeProps) => {
    return (
      <>
        {render}
        <SectionBrowser {...defaultProps} {...props} />
      </>
    )
  }

  return testRender(
    <Editor enabled={true} resolver={{BlankSection, NoSections}} onRender={renderNode}>
      <Frame>
        <BlankSection />
      </Frame>
    </Editor>,
  )
}

const getModal = () => {
  const heading = screen.getAllByText('Section Browser')[0]

  return heading.closest('[role="dialog"]') as HTMLElement
}

describe('SectionBrowser', () => {
  it('renders', () => {
    renderComponent()

    expect(screen.getAllByText('Section Browser')).toHaveLength(2)

    const modal = getModal()
    const closeButton = getByText(modal, 'Close')
    expect(closeButton).toBeInTheDocument()
    const sectionHeadings = modal.querySelectorAll('h3')
    expect(sectionHeadings).toHaveLength(8)
    expect(sectionHeadings[0]).toHaveTextContent('Hero')
    expect(sectionHeadings[1]).toHaveTextContent('Navigation')
    expect(sectionHeadings[2]).toHaveTextContent('About')
    expect(sectionHeadings[3]).toHaveTextContent('Callout Cards')
    expect(sectionHeadings[4]).toHaveTextContent('Quiz')
    expect(sectionHeadings[5]).toHaveTextContent('Announcement')
    expect(sectionHeadings[6]).toHaveTextContent('Footer')
    expect(sectionHeadings[7]).toHaveTextContent('Blank')
  })

  it('calls onClose on Close button click', async () => {
    const onClose = jest.fn()
    renderComponent({onClose})

    const modal = getModal()
    const closeButton = getByText(modal, 'Close').closest('button ') as HTMLButtonElement
    expect(closeButton).toBeInTheDocument()

    await user.click(closeButton)

    expect(onClose).toHaveBeenCalled()
  })
})
