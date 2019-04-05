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
import {fireEvent, render} from 'react-testing-library'

import Images from '..'

describe('RCE "Image" Plugin > Images', () => {
  let props
  let component

  beforeEach(() => {
    props = {
      fetchImages() {},
      images: {
        hasMore: false,
        isLoading: false,
        records: []
      },
      onImageEmbed() {}
    }
  })

  function renderComponent() {
    component = render(<Images {...props} />)
  }

  it('renders', () => {
    renderComponent()
    expect(component.container.children).toHaveLength(1)
  })
})
