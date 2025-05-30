/*
 * Copyright (C) 2015 - present Instructure, Inc.
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
import ModalContent from '../content'

describe('ModalContent', () => {
  test('applies className to parent node', () => {
    const {container} = render(<ModalContent className="cat" />)
    expect(container.firstChild).toHaveClass('cat')
  })

  test('renders children components', () => {
    const {container} = render(
      <ModalContent>
        <div className="my_fun_div" />
      </ModalContent>,
    )
    expect(container.querySelector('.my_fun_div')).toBeInTheDocument()
  })
})
