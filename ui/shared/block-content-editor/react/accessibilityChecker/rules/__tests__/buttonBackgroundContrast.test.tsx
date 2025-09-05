/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import {render, screen} from '@testing-library/react'
import {Button} from '@instructure/ui-buttons'
import {buttonBackgroundContrast} from '../buttonBackgroundContrast'
import {separatorLineContrast} from '../separatorLineContrast'

const white = '#FFFFFF'
const darkRed = '#632D2D'

describe('buttonBackgroundContrast with InstUI Button', () => {
  it('should pass for buttons with sufficient contrast', () => {
    render(
      <div style={{backgroundColor: white}}>
        <Button
          withBackground
          themeOverride={{secondaryBackground: darkRed, secondaryBorderColor: darkRed}}
        >
          High Contrast Button
        </Button>
      </div>,
    )

    const button = screen.getByRole('button')
    const result = buttonBackgroundContrast.test(button)

    expect(result).toBeTruthy()
  })

  it('should fail for buttons with insufficient contrast', () => {
    render(
      <div style={{backgroundColor: white}}>
        <Button
          withBackground
          themeOverride={{secondaryBackground: white, secondaryBorderColor: white}}
        >
          High Contrast Button
        </Button>
      </div>,
    )

    const button = screen.getByRole('button')
    const result = buttonBackgroundContrast.test(button)

    expect(result).toBeFalsy()
  })

  it('should handle buttons without parent background', () => {
    render(<button>Isolated Button</button>)

    const button = document.querySelector('button') as HTMLButtonElement
    const result = buttonBackgroundContrast.test(button)

    expect(result).toBeTruthy()
  })

  it('should pass for non-button elements', () => {
    render(<div>Not a button</div>)

    const div = document.querySelector('div') as HTMLDivElement
    const result = separatorLineContrast.test(div)

    expect(result).toBeTruthy()
  })
})
