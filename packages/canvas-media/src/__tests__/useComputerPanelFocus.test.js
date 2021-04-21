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

import React, {useRef} from 'react'
import {object, func, bool} from 'prop-types'
import {render} from '@testing-library/react'
import useComputerPanelFocus from '../useComputerPanelFocus'

function TestComponent(props) {
  const panelRef = useRef(null)
  const clearButtonRef = useRef(null)
  useComputerPanelFocus(props.theFile, panelRef, clearButtonRef)
  return (
    <div ref={panelRef}>
      {props && props.hasClearButton && (
        <button type="button" ref={clearButtonRef} onFocus={props.onButtonFocus}>
          clear button
        </button>
      )}
      <input onFocus={props.onInputFocus} />
    </div>
  )
}
TestComponent.propTypes = {
  theFile: object,
  onButtonFocus: func,
  onInputFocus: func,
  hasClearButton: bool
}
TestComponent.defaultProps = {
  hasClearButton: true
}

describe('useComputerPanelFocus hook', () => {
  it('does nothing until we have a file', () => {
    const onButtonFocus = jest.fn()
    const onInputFocus = jest.fn()
    render(
      <TestComponent theFile={null} onButtonFocus={onButtonFocus} onInputFocus={onInputFocus} />
    )

    expect(onButtonFocus).not.toHaveBeenCalled()
    expect(onInputFocus).not.toHaveBeenCalled()
  })

  it('focuses the button once we have a file', () => {
    const onButtonFocus = jest.fn()
    const onInputFocus = jest.fn()
    const theFile = {}
    render(
      <TestComponent theFile={theFile} onButtonFocus={onButtonFocus} onInputFocus={onInputFocus} />
    )

    expect(onButtonFocus).toHaveBeenCalled()
    expect(onInputFocus).not.toHaveBeenCalled()
  })

  it('focuses the input once we have a file, but no button', () => {
    const onButtonFocus = jest.fn()
    const onInputFocus = jest.fn()
    const theFile = {}
    render(
      <TestComponent
        theFile={theFile}
        onButtonFocus={onButtonFocus}
        onInputFocus={onInputFocus}
        hasClearButton={false}
      />
    )

    expect(onButtonFocus).not.toHaveBeenCalled()
    expect(onInputFocus).toHaveBeenCalled()
  })
})
