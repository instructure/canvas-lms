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
import {isRTL} from '@canvas/i18n/rtlHelper'

jest.mock('@canvas/i18n/rtlHelper', () => ({
  isRTL: jest.fn()
}))

describe('useResize', () => {
  const mockContainer = {
    x: 0,
    left: 0,
    y: 0,
    top: 0,
    width: 1000,
    height: 500,
    right: 1000,
    bottom: 500,
  }

  const mockDelimiter = {
    x: 250,
    left: 250,
    y: 0,
    top: 0,
    width: 10,
    height: 500,
    right: 260,
    bottom: 500,
  }

  const mockElement = () => {
    Element.prototype.getBoundingClientRect = jest
      .fn()
      .mockReturnValueOnce(mockContainer)
      .mockReturnValueOnce(mockDelimiter)
      .mockReturnValueOnce(mockContainer)
      .mockReturnValueOnce(mockDelimiter)
      .mockReturnValueOnce(mockContainer)
      .mockReturnValueOnce(mockDelimiter)
  }
  const TestComponent = () => {
    const {
      setContainerRef,
      setLeftColumnRef,
      setDelimiterRef,
      setRightColumnRef,
      onKeyDownHandler,
    } = useResize()
    return (
      <div ref={setContainerRef}>
        <div ref={setLeftColumnRef} data-testid="leftColumn" style={{width: '25%'}}>
          Left
        </div>
        {/* eslint-disable jsx-a11y/no-noninteractive-element-interactions, jsx-a11y/no-noninteractive-tabindex */}
        <div
          tabIndex="0"
          role="separator"
          aria-orientation="vertical"
          onKeyDown={onKeyDownHandler}
          ref={setDelimiterRef}
          data-testid="delimiter"
          style={{width: '1%'}}
        >
          Delimiter
        </div>
        {/* eslint-enable jsx-a11y/no-noninteractive-element-interactions, jsx-a11y/no-noninteractive-tabindex */}
        <div ref={setRightColumnRef} data-testid="rightColumn" style={{width: '74%'}}>
          Right
        </div>
      </div>
    )
  }

  beforeEach(() => {
    mockElement()
    isRTL.mockImplementation(() => false)
  })

  describe('With Mouse Navigation', () => {
    it('resizes the panes when clicking and moving the handler', () => {
      const {getByTestId} = render(<TestComponent />)
      const leftColumn = getByTestId('leftColumn')
      const rightColumn = getByTestId('rightColumn')
      const delimiter = getByTestId('delimiter')
      expect(leftColumn).toHaveStyle('width: 25%')
      expect(rightColumn).toHaveStyle('width: 74%')
      fireEvent.mouseDown(delimiter)
      fireEvent.mouseMove(delimiter, {
        clientX: 400,
      })
      expect(leftColumn).toHaveStyle('width: 400px')
      expect(rightColumn).toHaveStyle('width: 588px')
      fireEvent.mouseMove(delimiter, {
        clientX: 500,
      })
      expect(leftColumn).toHaveStyle('width: 500px')
      expect(rightColumn).toHaveStyle('width: 488px')
      fireEvent.mouseUp(delimiter)
      fireEvent.mouseMove(delimiter, {
        clientX: 600,
      })
      expect(leftColumn).toHaveStyle('width: 500px')
      expect(rightColumn).toHaveStyle('width: 488px')
    })

    it('does not resize the pans when clicking and moving an element that is not the handler', () => {
      const {getByTestId} = render(<TestComponent />)
      const leftColumn = getByTestId('leftColumn')
      const rightColumn = getByTestId('rightColumn')
      expect(leftColumn).toHaveStyle('width: 25%')
      expect(rightColumn).toHaveStyle('width: 74%')
      fireEvent.mouseDown(document)
      fireEvent.mouseMove(document, {
        clientX: 200,
      })
      expect(leftColumn).toHaveStyle('width: 25%')
      expect(rightColumn).toHaveStyle('width: 74%')
    })

    it('resizes the panes properly when RTL', () => {
      isRTL.mockImplementation(() => true)
      const {getByTestId} = render(<TestComponent />)
      const leftColumn = getByTestId('leftColumn')
      const rightColumn = getByTestId('rightColumn')
      const delimiter = getByTestId('delimiter')
      expect(leftColumn).toHaveStyle('width: 25%')
      expect(rightColumn).toHaveStyle('width: 74%')
      fireEvent.mouseDown(delimiter)
      fireEvent.mouseMove(delimiter, {
        clientX: 400,
      })
      expect(leftColumn).toHaveStyle('width: 588px')
      expect(rightColumn).toHaveStyle('width: 400px')
    })
  })

  describe('With Keyboard Only Navigation', () => {
    it('moves delimiter to the left in small increments using ArrowLeft key', () => {
      const {getByTestId} = render(<TestComponent />)
      expect(getByTestId('leftColumn')).toHaveStyle('width: 25%')
      expect(getByTestId('rightColumn')).toHaveStyle('width: 74%')
      fireEvent.keyDown(getByTestId('delimiter'), {
        key: 'ArrowLeft',
        keyCode: 37,
      })
      expect(getByTestId('leftColumn')).toHaveStyle('width: 245px')
      expect(getByTestId('rightColumn')).toHaveStyle('width: 743px')
    })

    it('moves delimiter to the right in small increments using ArrowRight key', () => {
      const {getByTestId} = render(<TestComponent />)
      expect(getByTestId('leftColumn')).toHaveStyle('width: 25%')
      expect(getByTestId('rightColumn')).toHaveStyle('width: 74%')
      fireEvent.keyDown(getByTestId('delimiter'), {
        key: 'ArrowRight',
        keyCode: 39,
      })
      expect(getByTestId('leftColumn')).toHaveStyle('width: 255px')
      expect(getByTestId('rightColumn')).toHaveStyle('width: 733px')
    })

    it('moves delimiter to the left in larger increments using PageDown key', () => {
      const {getByTestId} = render(<TestComponent />)
      expect(getByTestId('leftColumn')).toHaveStyle('width: 25%')
      expect(getByTestId('rightColumn')).toHaveStyle('width: 74%')
      fireEvent.keyDown(getByTestId('delimiter'), {
        key: 'PageDown',
        keyCode: 34,
      })
      expect(getByTestId('leftColumn')).toHaveStyle('width: 225px')
      expect(getByTestId('rightColumn')).toHaveStyle('width: 763px')
    })

    it('moves delimiter to the right in larger increments using PageUp key', () => {
      const {getByTestId} = render(<TestComponent />)
      expect(getByTestId('leftColumn')).toHaveStyle('width: 25%')
      expect(getByTestId('rightColumn')).toHaveStyle('width: 74%')
      fireEvent.keyDown(getByTestId('delimiter'), {
        key: 'PageUp',
        keyCode: 33,
      })
      expect(getByTestId('leftColumn')).toHaveStyle('width: 275px')
      expect(getByTestId('rightColumn')).toHaveStyle('width: 713px')
    })

    it('resizes the panes properly when RTL', () => {
      isRTL.mockImplementation(() => true)
      const {getByTestId} = render(<TestComponent />)
      expect(getByTestId('leftColumn')).toHaveStyle('width: 25%')
      expect(getByTestId('rightColumn')).toHaveStyle('width: 74%')
      fireEvent.keyDown(getByTestId('delimiter'), {
        key: 'ArrowLeft',
        keyCode: 37,
      })
      expect(getByTestId('leftColumn')).toHaveStyle('width: 743px')
      expect(getByTestId('rightColumn')).toHaveStyle('width: 245px')
    })
  })

  describe('Delimiter attributes', () => {
    it('has aria-valuenow', () => {
      const {getByTestId} = render(<TestComponent />)
      expect(getByTestId('delimiter')).toHaveAttribute('aria-valuenow')
    })
  })
})
