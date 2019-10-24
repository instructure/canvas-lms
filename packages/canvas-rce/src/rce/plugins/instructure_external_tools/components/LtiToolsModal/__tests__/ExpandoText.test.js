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
import {render, fireEvent} from '@testing-library/react'

import ExpandoText from '../ExpandoText'

describe('RCE Plugins > LtiTool', () => {
  function renderComponent(text) {
    return render(
      <div style={{width: '10rem'}}>
        <ExpandoText text={text} />)
      </div>
    )
  }

  it('renters right-arrow when first rendered', () => {
    const {container} = renderComponent('hello world')
    expect(container.querySelector('svg[name="IconArrowOpenEnd"]')).toBeInTheDocument()
  })

  it('renders the text', () => {
    const {getByText} = renderComponent('hello world')
    expect(getByText('hello world')).toBeInTheDocument()
  })

  it('renders the down-arrow when expanded', () => {
    const {container} = renderComponent('hello world')
    const arrowButton = container.querySelector('svg[name="IconArrowOpenEnd"]')
    fireEvent.click(arrowButton)
    expect(container.querySelector('svg[name="IconArrowOpenDown"]')).toBeInTheDocument()
  })

  it('renders the right-arrow when collapsed', () => {
    const {container} = renderComponent('hello world')
    fireEvent.click(container.querySelector('svg[name="IconArrowOpenEnd"]'))
    const downButton = container.querySelector('svg[name="IconArrowOpenDown"]')
    expect(downButton).toBeInTheDocument()
    fireEvent.click(downButton)
    expect(container.querySelector('svg[name="IconArrowOpenEnd"]')).toBeInTheDocument()
  })
})
