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

import {RotationControls} from '../RotationControls'

jest.useFakeTimers()

describe('RotationControls', () => {
  it('renders buttons', () => {
    const {container} = render(<RotationControls />)
    const rotateLeftButton = container.querySelectorAll('button')[0]
    const rotateRightButton = container.querySelectorAll('button')[1]
    expect(rotateLeftButton).toBeInTheDocument()
    expect(rotateRightButton).toBeInTheDocument()
  })

  it('calls function when rotate left is clicked', () => {
    const callback = jest.fn()
    const {container} = render(<RotationControls onChange={callback} />)
    const rotateLeftButton = container.querySelectorAll('button')[0]
    fireEvent.click(rotateLeftButton)
    expect(callback).toHaveBeenCalledWith(-90)
  })

  it('calls function rotate right in is clicked', () => {
    const callback = jest.fn()
    const {container} = render(<RotationControls onChange={callback} />)
    const rotateRightButton = container.querySelectorAll('button')[1]
    fireEvent.click(rotateRightButton)
    expect(callback).toHaveBeenCalledWith(90)
  })

  describe('sets angle manually', () => {
    const timeout = 2000

    it('increment using up arrow', () => {
      const callback = jest.fn()
      const {container} = render(<RotationControls onChange={callback} />)
      const input = container.querySelector('label input[type="text"]')
      fireEvent.keyDown(input, {keyCode: 38})
      expect(callback).toHaveBeenCalledWith(1)
    })

    it('increment using down arrow', () => {
      const callback = jest.fn()
      const {container} = render(<RotationControls onChange={callback} />)
      const input = container.querySelector('label input[type="text"]')
      fireEvent.keyDown(input, {keyCode: 40})
      expect(callback).toHaveBeenCalledWith(-1)
    })

    describe('on blur input', () => {
      it('with custom valid positive angle', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '10º'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(10)
      })

      it('with custom valid positive value that exceeds 360', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '370'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(10)
      })

      it('with custom valid positive angle with decimals', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '10.100º'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(10)
      })

      it('with custom valid positive angle without º symbol', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '15'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(15)
      })

      it('with custom valid positive angle with decimals and without º symbol', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '15.201'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(15)
      })

      it('with custom valid negative angle', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-10º'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(-10)
      })

      it('with custom valid negative value that is lower than -360', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-370'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(-10)
      })

      it('with custom valid negative angle with decimals', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-10.100º'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(-10)
      })

      it('with custom valid negative angle without º symbol', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-15'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(-15)
      })

      it('with custom valid negative angle with decimals and without º symbol', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-15.201'}})
        fireEvent.blur(input)
        expect(callback).toHaveBeenCalledWith(-15)
      })

      it('with custom invalid angle', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: 'banana'}})
        fireEvent.blur(input)
        expect(callback).not.toHaveBeenCalled()
      })

      it('with custom empty angle', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: ''}})
        fireEvent.blur(input)
        expect(callback).not.toHaveBeenCalled()
      })

      it('with shows error message', () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: ''}})
        fireEvent.blur(input)
        const messageContainer = container.querySelector('label > span > span:last-child')
        expect(messageContainer.textContent).toEqual('Invalid entry.')
      })
    })

    describe('on change and debounce input', () => {
      it('with custom valid positive angle', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '10º'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(10)
          },
          {timeout}
        )
      })

      it('with custom valid positive value that exceeds 360', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '370'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(10)
          },
          {timeout}
        )
      })

      it('with custom valid positive angle with decimals', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '10.100º'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(10)
          },
          {timeout}
        )
      })

      it('with custom valid positive angle without º symbol', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '15'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(15)
          },
          {timeout}
        )
      })

      it('with custom valid positive angle with decimals and without º symbol', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '15.201'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(15)
          },
          {timeout}
        )
      })

      it('with custom valid negative angle', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-10º'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(-10)
          },
          {timeout}
        )
      })

      it('with custom valid negative value that is lower than -360', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-370'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(-10)
          },
          {timeout}
        )
      })

      it('with custom valid negative angle with decimals', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-10.100º'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(-10)
          },
          {timeout}
        )
      })

      it('with custom valid negative angle without º symbol', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-15'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(-15)
          },
          {timeout}
        )
      })

      it('with custom valid negative angle with decimals and without º symbol', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: '-15.201'}})
        await waitFor(
          () => {
            expect(callback).toHaveBeenCalledWith(-15)
          },
          {timeout}
        )
      })

      it('with custom invalid angle', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
        const input = container.querySelector('label input[type="text"]')
        fireEvent.change(input, {target: {value: 'banana'}})
        await waitFor(
          () => {
            expect(callback).not.toHaveBeenCalled()
          },
          {timeout}
        )
      })

      it('with custom empty angle', async () => {
        const callback = jest.fn()
        const {container} = render(<RotationControls onChange={callback} />)
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
        const {container} = render(<RotationControls onChange={callback} />)
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
})
