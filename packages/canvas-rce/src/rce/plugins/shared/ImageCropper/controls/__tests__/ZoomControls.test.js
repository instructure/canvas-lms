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
import {fireEvent, render, waitFor} from '@testing-library/react'
import {ZoomControls} from '../ZoomControls'
import {BUTTON_SCALE_STEP} from '../../constants'
import round from '../../../round'
import {showFlashAlert} from '../../../../../../common/FlashAlert'

jest.mock('../../../../../../common/FlashAlert')
jest.mock('@instructure/debounce', () => ({
  debounce: fn => {
    return fn
  },
}))

describe('ZoomControls', () => {
  it('renders buttons with min scale ratio', () => {
    const {container} = render(<ZoomControls scaleRatio={1} />)
    const zoomOutButton = container.querySelectorAll('button')[0]
    const zoomInButton = container.querySelectorAll('button')[1]
    expect(zoomOutButton.hasAttribute('disabled')).toBeTruthy()
    expect(zoomInButton.hasAttribute('disabled')).toBeFalsy()
  })

  it('renders buttons with max scale ratio', () => {
    const {container} = render(<ZoomControls scaleRatio={2} />)
    const zoomOutButton = container.querySelectorAll('button')[0]
    const zoomInButton = container.querySelectorAll('button')[1]
    expect(zoomOutButton.hasAttribute('disabled')).toBeFalsy()
    expect(zoomInButton.hasAttribute('disabled')).toBeTruthy()
  })

  it('renders buttons with average scale ratio', () => {
    const ratio = 1.5
    const {container} = render(<ZoomControls scaleRatio={ratio} />)
    const zoomOutButton = container.querySelectorAll('button')[0]
    const zoomInButton = container.querySelectorAll('button')[1]
    expect(zoomOutButton.hasAttribute('disabled')).toBeFalsy()
    expect(zoomInButton.hasAttribute('disabled')).toBeFalsy()
  })

  it('calls function when zoom out is clicked', () => {
    const callback = jest.fn()
    const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
    const zoomOutButton = container.querySelectorAll('button')[0]
    fireEvent.click(zoomOutButton)
    expect(callback).toHaveBeenCalledWith(1.4)
  })

  it('calls function when zoom in is clicked', () => {
    const callback = jest.fn()
    const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
    const zoomInButton = container.querySelectorAll('button')[1]
    fireEvent.click(zoomInButton)
    expect(callback).toHaveBeenCalledWith(1.6)
  })

  describe('sets zoom manually', () => {
    const timeout = 2000

    it('increment using up arrow', () => {
      const callback = jest.fn()
      const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
      const input = container.querySelector('label input[type="text"]')
      fireEvent.keyDown(input, {keyCode: 38})
      expect(callback).toHaveBeenCalledWith(1.51)
    })

    it('increment using down arrow', () => {
      const callback = jest.fn()
      const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
      const input = container.querySelector('label input[type="text"]')
      fireEvent.keyDown(input, {keyCode: 40})
      expect(callback).toHaveBeenCalledWith(1.49)
    })

    describe('on blur input', () => {
      it('with custom valid positive percentage', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '150%'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(1.5)
      })

      it('with custom valid positive value that is lower than 100', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '90%'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(1)
      })

      it('with custom valid positive value that is greater than 200', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '300%'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(2)
      })

      it('with custom valid positive percentage with decimals', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '150.100%'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(1.5)
      })

      it('with custom valid positive percentage without % symbol', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '150'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(1.5)
      })

      it('with custom valid positive percentage with decimals and without % symbol', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '150.201'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(1.5)
      })

      it('with custom valid negative percentage', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-100%'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(1)
      })

      it('with custom valid negative percentage with decimals', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-100.100%'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(1)
      })

      it('with custom valid negative percentage without % symbol', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-100'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(1)
      })

      it('with custom valid negative percentage with decimals and without % symbol', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-150.201'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(1)
      })

      it('with custom invalid percentage', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: 'banana'}})
        fireEvent.blur(input)
        expect(callback).not.toHaveBeenCalled()
      })

      it('with custom empty percentage', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: ''}})
        fireEvent.blur(input)
        expect(callback).not.toHaveBeenCalled()
      })

      it('with shows error message', () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: ''}})
        fireEvent.blur(input)
        const messageContainer = container.querySelector('label > span > span:last-child')
        expect(messageContainer.textContent).toEqual('Invalid entry.')
      })
    })

    describe('on change and debounce input', () => {
      it('with custom valid positive percentage', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '150%'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(1.5)
          },
          {timeout}
        )
      })

      it('with custom valid positive value that exceeds 200', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '300'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(2)
          },
          {timeout}
        )
      })

      it('with custom valid positive percentage with decimals', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '150.100%'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(1.5)
          },
          {timeout}
        )
      })

      it('with custom valid positive percentage without % symbol', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '150'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(1.5)
          },
          {timeout}
        )
      })

      it('with custom valid positive percentage with decimals and without % symbol', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '150.201'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(1.5)
          },
          {timeout}
        )
      })

      it('with custom valid negative percentage', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-150%'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(1)
          },
          {timeout}
        )
      })

      it('with custom valid negative percentage with decimals', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-150.100%'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(1)
          },
          {timeout}
        )
      })

      it('with custom valid negative percentage without % symbol', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-150'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(1)
          },
          {timeout}
        )
      })

      it('with custom valid negative percentage with decimals and without % symbol', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls scaleRatio={1.5} onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-150.201'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(1)
          },
          {timeout}
        )
      })

      it('with custom invalid percentage', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: 'banana'}})
        await waitFor(
          () => {
            expect(callback).not.toHaveBeenCalled()
          },
          {timeout}
        )
      })

      it('with custom empty percentage', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: ''}})
        await waitFor(
          () => {
            expect(callback).not.toHaveBeenCalled()
          },
          {timeout}
        )
      })

      it('with shows error message', async () => {
        const callback = jest.fn()
        const {container} = render(<ZoomControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: ''}})
        await waitFor(
          () => {
            const messageContainer = container.querySelector('label > span > span:last-child')
            expect(messageContainer.textContent).toEqual('Invalid entry.')
          },
          {timeout}
        )
      })
    })
  })

  describe('fires off screenreader alerts', () => {
    let scaleRatio, props

    const expectedMessage = ratio => {
      return {
        message: `${round(ratio) * 100}% Zoom`,
        type: 'info',
        srOnly: true,
      }
    }

    beforeAll(() => {
      scaleRatio = 1.5

      props = {
        scaleRatio,
        onChange: () => {},
      }
    })

    it('when zoom in button is pressed', () => {
      const {getByRole} = render(<ZoomControls {...props} />)
      const zoomInButton = getByRole('button', {name: /zoom in image/i})
      fireEvent.click(zoomInButton)
      expect(showFlashAlert).toHaveBeenLastCalledWith(
        expectedMessage(scaleRatio + BUTTON_SCALE_STEP)
      )
    })

    it('when zoom out button is pressed', () => {
      const {getByRole} = render(<ZoomControls {...props} />)
      const zoomOutButton = getByRole('button', {name: /zoom out image/i})
      fireEvent.click(zoomOutButton)
      expect(showFlashAlert).toHaveBeenLastCalledWith(
        expectedMessage(scaleRatio - BUTTON_SCALE_STEP)
      )
    })

    it('when zoom input is mutated with arrow keys', () => {
      const {container} = render(<ZoomControls {...props} />)
      const input = container.querySelector('label input[type="text"]')
      fireEvent.keyDown(input, {keyCode: 38}) // up arrow
      expect(showFlashAlert).toHaveBeenLastCalledWith(expectedMessage(1.51))
    })

    it('when zoom input is mutated by direct entry', () => {
      const {container} = render(<ZoomControls {...props} />)
      const input = container.querySelector('label input[type="text"]')
      fireEvent.change(input, {target: {value: '125'}})
      expect(showFlashAlert).toHaveBeenLastCalledWith(expectedMessage(1.25))
    })
  })
})
