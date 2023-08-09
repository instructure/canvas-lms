/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import MathIcon from '../index'

const renderMathIcon = command => {
  const {queryByTestId} = render(<MathIcon command={command} />)
  const mathSymbolIcon = queryByTestId('math-symbol-icon')
  const warningIcon = queryByTestId('warning-icon')
  return [mathSymbolIcon, warningIcon]
}

describe('MathIcon', () => {
  it('renders an SVGIcon when given a valid command', () => {
    const [mathSymbolIcon, warningIcon] = renderMathIcon('\\otimes')
    expect(mathSymbolIcon).toBeInTheDocument()
    expect(warningIcon).not.toBeInTheDocument()
  })

  it('renders a warning icon when given an invalid command', () => {
    const [mathSymbolIcon, warningIcon] = renderMathIcon('invalidcommand')
    expect(mathSymbolIcon).not.toBeInTheDocument()
    expect(warningIcon).toBeInTheDocument()
  })
})
