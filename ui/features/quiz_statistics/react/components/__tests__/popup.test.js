/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {render} from '@testing-library/react'
import React from 'react'
import Popup from '../popup'

describe('canvas_quizzes/components/popup', () => {
  it('renders', () => {
    function Content() {
      return <span>yea!</span>
    }

    render(<Popup content={Content} />)

    expect(document.body.textContent).toMatch('yea!')
  })

  it('changes content', () => {
    function One() {
      return <span>one</span>
    }

    function Two() {
      return <span>two</span>
    }

    render(<Popup content={One} />)

    expect(document.body.textContent).toMatch('one')

    render(<Popup content={Two} />)

    expect(document.body.textContent).toMatch('two')
  })

  it('updates content props', () => {
    function Content({someContentProp}) {
      return <span>{someContentProp}</span>
    }

    render(<Popup content={Content} someContentProp="one" />)

    expect(document.body.textContent).toMatch('one')

    render(<Popup content={Content} someContentProp="two" />)

    expect(document.body.textContent).toMatch('two')
  })
})
