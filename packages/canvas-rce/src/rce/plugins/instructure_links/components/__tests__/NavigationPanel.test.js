/*
 * Copyright (C) 2019 - present Instructure, Inc.
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
import NavigationPanel from '../NavigationPanel'

function renderComponent(props) {
  return render(
    <NavigationPanel
      contextType="course"
      contextId="1"
      onChangeAccordion={() => {}}
      selectedAccordionIndex=""
      onLinkClick={() => {}}
      {...props}
    />
  )
}

describe('RCE "Links" Plugin > NavigationPanel', () => {
  it('renders closed', () => {
    const {getByText} = renderComponent()

    expect(getByText('Course Navigation')).toBeInTheDocument()
    expect(getByText('Expand to see Course Navigation')).toBeInTheDocument()
  })

  it('renders course navigation open', () => {
    const {getByText, getAllByTestId} = renderComponent({selectedAccordionIndex: 'navigation'})

    expect(getByText('Course Navigation')).toBeInTheDocument()
    expect(getByText('Collapse to hide Course Navigation')).toBeInTheDocument()
    expect(getAllByTestId('instructure_links-Link')).toHaveLength(12)
  })

  it('renders group navigation open', () => {
    const {getByText, getAllByTestId} = renderComponent({
      selectedAccordionIndex: 'navigation',
      contextType: 'group',
    })

    expect(getByText('Group Navigation')).toBeInTheDocument()
    expect(getByText('Collapse to hide Group Navigation')).toBeInTheDocument()
    expect(getAllByTestId('instructure_links-Link')).toHaveLength(6)
  })
})
