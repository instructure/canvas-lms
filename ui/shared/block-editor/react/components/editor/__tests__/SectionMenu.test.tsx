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
// eslint-disable-next-line @typescript-eslint/no-unused-vars
import {Editor, Frame, useEditor} from '@craftjs/core'

import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import {SectionMenu, type SectionMenuProps} from '../SectionMenu'
import type {AddSectionPlacement} from '../types'
import {BlankSection} from '../../user/sections/BlankSection'
import {NoSections} from '../../user/common'

const user = userEvent.setup()

let getDescendants: () => string[]
const fauxNode = {
  id: '1',
  data: {
    parent: 'ROOT',
  },
}

jest.mock('@craftjs/core', () => {
  const module = jest.requireActual('@craftjs/core')
  return {
    ...module,
    useEditor: jest.fn(() => {
      return {
        query: {
          node: (_id: string) => {
            return {
              descendants: getDescendants,
            }
          },
        },
        selected: {
          get: () => fauxNode,
          isDeletable: () => true,
        },
        actions: {},
      }
    }),
  }
})

const defaultProps = {
  onEditSection: undefined,
  onAddSection: (_placement: AddSectionPlacement) => {},
  onMoveUp: undefined,
  onMoveDown: undefined,
  onRemove: undefined,
}

const renderComponent = (props: Partial<SectionMenuProps> = {}) => {
  const renderNode = () => {
    return <SectionMenu {...defaultProps} {...props} />
  }

  return render(
    <Editor enabled={true} resolver={{BlankSection, NoSections}} onRender={renderNode}>
      <Frame>
        <BlankSection />
      </Frame>
    </Editor>
  )
}

describe('SectionMenu', () => {
  beforeEach(() => {
    getDescendants = () => ['3', '1', '2']
  })

  it('renders', async () => {
    const {getByText} = renderComponent()

    expect(getByText('+ Section Above')).toBeInTheDocument()
    expect(getByText('+ Section Below')).toBeInTheDocument()
    expect(getByText('Move Up')).toBeInTheDocument()
    expect(getByText('Move Down')).toBeInTheDocument()
    expect(getByText('Remove')).toBeInTheDocument()
  })

  it('calls onAddSection with placement prepend', async () => {
    const onAddSection = jest.fn()
    const {getByText} = renderComponent({onAddSection})

    await user.click(getByText('+ Section Above'))

    expect(onAddSection).toHaveBeenCalledWith('prepend')
  })

  it('calls onAddSection with placement append', async () => {
    const onAddSection = jest.fn()
    const {getByText} = renderComponent({onAddSection})

    await user.click(getByText('+ Section Below'))

    expect(onAddSection).toHaveBeenCalledWith('append')
  })

  it('calls onMoveUp', async () => {
    const onMoveUp = jest.fn()
    const {getByText} = renderComponent({onMoveUp})

    await user.click(getByText('Move Up'))

    expect(onMoveUp).toHaveBeenCalled()
  })

  it('calls onMoveDown', async () => {
    const onMoveDown = jest.fn()
    const {getByText} = renderComponent({onMoveDown})

    await user.click(getByText('Move Down'))

    expect(onMoveDown).toHaveBeenCalled()
  })

  it('calls onRemove', async () => {
    const onRemove = jest.fn()
    const {getByText} = renderComponent({onRemove})

    await user.click(getByText('Remove'))

    expect(onRemove).toHaveBeenCalled()
  })

  it('disables Move Up when at the top', async () => {
    getDescendants = () => ['1', '2']
    const onMoveUp = jest.fn()
    const {getByText} = renderComponent({onMoveUp})

    const menuitem = getByText('Move Up').closest('[role="menuitem"]')
    expect(menuitem).toHaveAttribute('aria-disabled', 'true')
  })

  it('disables Move Down when at the bottom', async () => {
    getDescendants = () => ['2', '1']
    const onMoveDown = jest.fn()
    const {getByText} = renderComponent({onMoveDown})

    const menuitem = getByText('Move Down').closest('[role="menuitem"]')
    expect(menuitem).toHaveAttribute('aria-disabled', 'true')
  })
})
