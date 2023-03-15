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
import {fireEvent, render} from '@testing-library/react'

import ExpandoText from '../util/ExpandoText'

describe('RCE Plugins > ExternalToolSelectionItem', () => {
  function renderComponent(text: string, title = 'title') {
    return render(
      <div style={{width: '10rem'}}>
        <ExpandoText text={text} title={title} />)
      </div>
    )
  }

  it('renders View description when first rendered', () => {
    const {getByText} = renderComponent('hello world')
    expect(getByText('View description')).toBeInTheDocument()
  })

  it('renders description when expanded', () => {
    const {getByText} = renderComponent('hello world')
    const toggleDescButton = getByText('View description')
    fireEvent.click(toggleDescButton)
    expect(getByText('Hide description')).toBeInTheDocument()
    expect(getByText('hello world')).toBeInTheDocument()
  })

  it('renders View description when collapsed', () => {
    const {getByText} = renderComponent('hello world')
    fireEvent.click(getByText('View description'))
    const toggleDescButton = getByText('Hide description')
    expect(toggleDescButton).toBeInTheDocument()
    fireEvent.click(toggleDescButton)
    expect(getByText('View description')).toBeInTheDocument()
  })
})
