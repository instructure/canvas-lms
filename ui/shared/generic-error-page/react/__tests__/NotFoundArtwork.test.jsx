/*
 * Copyright (C) 2018 - present Instructure, Inc.
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
import NotFoundArtwork from '../NotFoundArtwork'

const renderNotFoundArtwork = () => render(<NotFoundArtwork />)

describe('NotFoundArtwork', () => {
  it('renders the NotFoundArtwork component', () => {
    const wrapper = renderNotFoundArtwork()

    expect(wrapper.container).toBeInTheDocument()
  })

  it('renders the NotFoundArtwork renders correct header', () => {
    const wrapper = renderNotFoundArtwork()

    expect(wrapper.getByText('Whoops... Looks like nothing is here!')).toBeInTheDocument()
  })

  it('renders the NotFoundArtwork component help description', () => {
    const wrapper = renderNotFoundArtwork()

    expect(wrapper.getByText("We couldn't find that page!")).toBeInTheDocument()
  })
})
