/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import {render, cleanup} from '@testing-library/react'
import {userEvent} from '@testing-library/user-event'
import SectionTooltip from '../index'

const defaultProps = () => ({
  sections: [{id: 2, name: 'sections name', user_count: 4}],
  totalUserCount: 5,
})

const renderSectionTooltip = (props = {}) =>
  render(<SectionTooltip {...defaultProps()} {...props} />)

describe('SectionTooltip', () => {
  afterEach(() => {
    cleanup()
  })

  it('renders the SectionTooltip component', () => {
    const tree = renderSectionTooltip()

    expect(tree.container).toBeInTheDocument()
  })

  it('renders the correct section text', () => {
    const tree = renderSectionTooltip()
    const node = tree.getAllByText('1 Section')[0]
    const screenReaderNode = tree.getAllByText('sections name')[0]

    expect(node).toBeInTheDocument()
    expect(screenReaderNode).toBeInTheDocument()
  })

  it('renders prefix text when passed in', () => {
    const props = {
      ...defaultProps(),
      prefix: 'Anonymous Discussion | ',
    }
    const tree = renderSectionTooltip(props)
    const node = tree.getByText('Anonymous Discussion | 1 Section')

    expect(node).toBeInTheDocument()
  })

  it('uses textColor from props', () => {
    const props = {
      ...defaultProps(),
      textColor: 'secondary',
    }
    const tree = renderSectionTooltip(props)
    const node = tree.container.querySelector('span[color="secondary"]')

    expect(node).toBeInTheDocument()
  })

  it('renders all sections if no sections are given', () => {
    const props = {
      ...defaultProps(),
      sections: null,
    }
    const tree = renderSectionTooltip(props)
    const allSectionsText = tree.getByText('All Sections')

    expect(allSectionsText).toBeInTheDocument()
  })

  it('renders tooltip text correcly with sections', async () => {
    const tree = renderSectionTooltip()

    await userEvent.hover(tree.container.querySelector('span[data-cid="Position Popover Tooltip"]'))

    expect(document.querySelector('span[role="tooltip"]').textContent).toEqual(
      'sections name (4 Users)'
    )
  })

  it('renders multiple sections into tooltip', async () => {
    const props = {
      ...defaultProps(),
      sections: [
        {id: 2, name: 'sections name', user_count: 4},
        {id: 3, name: 'section other name', user_count: 8},
      ],
    }
    const tree = renderSectionTooltip(props)

    await userEvent.hover(tree.container.querySelector('span[data-cid="Position Popover Tooltip"]'))

    expect(document.querySelector('span[role="tooltip"]').textContent).toEqual(
      'sections name (4 Users)section other name (8 Users)'
    )
  })

  it('renders All Sections and default tooltip', async () => {
    const props = {
      ...defaultProps(),
      sections: null,
    }
    const tree = renderSectionTooltip(props)
    const allSectionsText = tree.getByText('All Sections')

    await userEvent.hover(tree.container.querySelector('span[data-cid="Position Popover Tooltip"]'))

    expect(allSectionsText).toBeInTheDocument()
    expect(document.querySelector('span[role="tooltip"]').textContent).toEqual('(5 Users)')
  })
})
