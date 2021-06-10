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

import React from 'react'
import useResize from '../useResize'
import {render, fireEvent} from '@testing-library/react'
import * as rtlHelper from '@canvas/i18n/rtlHelper'

describe('useResize', () => {
  const TmpComponent = () => {
    const {setContainerRef, setLeftColumnRef, setDelimiterRef, setRightColumnRef} = useResize()

    return (
      <div ref={setContainerRef}>
        <div ref={setLeftColumnRef} data-testid="leftColumn" style={{width: '25%'}}>
          Left
        </div>
        <div ref={setDelimiterRef} data-testid="delimiter" style={{width: '1%'}}>
          Delimiter
        </div>
        <div ref={setRightColumnRef} data-testid="rightColumn" style={{width: '74%'}}>
          Right
        </div>
      </div>
    )
  }

  beforeEach(() => {
    Element.prototype.getBoundingClientRect = jest.fn(() => {
      return {
        width: 1000,
        height: 120,
        top: 0,
        left: 0,
        bottom: 0,
        right: 0
      }
    })
  })

  it('resizes the panes when clicking and moving the handler', () => {
    const {getByTestId} = render(<TmpComponent />)
    expect(getByTestId('leftColumn')).toHaveStyle('width: 25%')
    expect(getByTestId('rightColumn')).toHaveStyle('width: 74%')
    fireEvent.mouseDown(getByTestId('delimiter'))
    fireEvent.mouseMove(getByTestId('delimiter'), {
      clientX: 400
    })
    expect(getByTestId('leftColumn')).toHaveStyle('width: 392px')
    expect(getByTestId('rightColumn')).toHaveStyle('width: 600px')
    fireEvent.mouseMove(getByTestId('delimiter'), {
      clientX: 500
    })
    expect(getByTestId('leftColumn')).toHaveStyle('width: 492px')
    expect(getByTestId('rightColumn')).toHaveStyle('width: 500px')
    fireEvent.mouseUp(getByTestId('delimiter'))
    fireEvent.mouseMove(getByTestId('delimiter'), {
      clientX: 600
    })
    expect(getByTestId('leftColumn')).toHaveStyle('width: 492px')
    expect(getByTestId('rightColumn')).toHaveStyle('width: 500px')
  })

  it('does not resize the pans when clicking and moving an element that is not the handler', () => {
    const {getByTestId} = render(<TmpComponent />)
    expect(getByTestId('leftColumn')).toHaveStyle('width: 25%')
    expect(getByTestId('rightColumn')).toHaveStyle('width: 74%')
    fireEvent.mouseDown(document)
    fireEvent.mouseMove(document, {
      clientX: 200
    })
    expect(getByTestId('leftColumn')).toHaveStyle('width: 25%')
    expect(getByTestId('rightColumn')).toHaveStyle('width: 74%')
  })

  it('resizes the panes properly when RTL', () => {
    jest.spyOn(rtlHelper, 'isRTL').mockImplementation(_e => {
      return true
    })

    const {getByTestId} = render(<TmpComponent />)
    expect(getByTestId('leftColumn')).toHaveStyle('width: 25%')
    expect(getByTestId('rightColumn')).toHaveStyle('width: 74%')
    fireEvent.mouseDown(getByTestId('delimiter'))
    fireEvent.mouseMove(getByTestId('delimiter'), {
      clientX: 400
    })
    expect(getByTestId('leftColumn')).toHaveStyle('width: 600px')
    expect(getByTestId('rightColumn')).toHaveStyle('width: 392px')
  })
})
