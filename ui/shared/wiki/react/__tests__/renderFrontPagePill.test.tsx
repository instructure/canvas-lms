/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {screen, render} from '@testing-library/react'
import {renderFrontPagePill} from '../renderFrontPagePill'

const removePillContainer = (): void => {
  const container = document.querySelector('.front-page')
  if (container) document.body.removeChild(container)
}

describe('renderFrontPagePill', () => {
  it('renders the pill with whatever text you pass it', () => {
    const container = document.createElement('div')
    container.className = 'front-page'

    const frontPagePill = renderFrontPagePill(container, {children: 'Front Page'})

    const {getByText} = render(frontPagePill)
    const pill = getByText('Front Page')
    expect(pill).toBeInTheDocument()

    removePillContainer()
  })

  it('does not render a pill if there is no front page container in the dom', () => {
    const container = document.createElement('div')
    removePillContainer()
    renderFrontPagePill(container, {children: 'Front Page'})
    const pill = screen.queryByText('Front Page')
    expect(pill).not.toBeInTheDocument()
  })
})
