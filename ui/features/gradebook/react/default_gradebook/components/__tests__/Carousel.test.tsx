/*
 * Copyright (C) 2017 - present Instructure, Inc.
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
import Carousel from '../Carousel'
import {userEvent} from '@testing-library/user-event'

let props: any = {}

function subject(specific_props: any) {
  return render(<Carousel {...specific_props} />)
}

describe('Carousel', () => {
  beforeEach(() => {
    props = {
      children: 'Book Report',
      disabled: false,
      displayLeftArrow: false,
      displayRightArrow: false,
      leftArrowDescription: 'Previous',
      onLeftArrowClick: () => {},
      onRightArrowClick: () => {},
      rightArrowDescription: 'Next',
    }
  })

  test('renders children', function () {
    subject(props)
    expect(screen.getByText('Book Report')).toBeInTheDocument()
  })

  test('does not render left arrow when displayLeftArrow is false', function () {
    subject(props)
    expect(screen.queryByText('Previous')).not.toBeInTheDocument()
  })

  test('renders left arrow when displayLeftArrow is true', function () {
    props.displayLeftArrow = true
    subject(props)
    expect(screen.getByText('Previous')).toBeInTheDocument()
  })

  test('does not render right arrow when displayRightArrow is false', function () {
    subject(props)
    expect(screen.queryByText('Next')).not.toBeInTheDocument()
  })

  test('renders right arrow when displayRightArrow is true', function () {
    props.displayRightArrow = true
    subject(props)
    expect(screen.getByText('Next')).toBeInTheDocument()
  })

  test('calls onLeftArrowClick when left arrow is clicked', async function () {
    props.displayLeftArrow = true
    props.onLeftArrowClick = jest.fn()
    subject(props)
    await userEvent.click(screen.getByRole('button', {name: 'Previous'}))
    expect(props.onLeftArrowClick).toHaveBeenCalledTimes(1)
  })

  test('calls onRightArrowClick when right arrow is clicked', async function () {
    props.displayRightArrow = true
    props.onRightArrowClick = jest.fn()
    subject(props)
    await userEvent.click(screen.getByRole('button', {name: 'Next'}))
    expect(props.onRightArrowClick).toHaveBeenCalledTimes(1)
  })

  test('focuses right arrow on right arrow click when both arrows are displayed', async function () {
    subject({...props, ...{displayLeftArrow: true, displayRightArrow: true}})
    const rightButton = screen.getByRole('button', {name: 'Next'})
    await userEvent.click(rightButton)
    expect(rightButton.matches(':focus')).toBe(true)
  })

  test('focuses left arrow on left arrow click when both arrows are displayed', async function () {
    subject({...props, ...{displayLeftArrow: true, displayRightArrow: true}})
    const leftButton = screen.getByRole('button', {name: 'Previous'})
    await userEvent.click(leftButton)
    expect(leftButton.matches(':focus')).toBe(true)
  })

  test('focuses left arrow when transitioning from displaying both arrows to only the left arrow', function () {
    const {rerender} = render(
      <Carousel {...props} displayLeftArrow={true} displayRightArrow={true} />
    )
    const leftButton = screen.getByRole('button', {name: 'Previous'})
    rerender(<Carousel {...props} displayLeftArrow={true} displayRightArrow={false} />)
    expect(leftButton.matches(':focus')).toBe(true)
  })

  test('focuses right arrow when transitioning from displaying both arrows to only the right arrow', function () {
    const {rerender} = render(
      <Carousel {...props} displayLeftArrow={true} displayRightArrow={true} />
    )
    const rightButton = screen.getByRole('button', {name: 'Next'})
    rerender(<Carousel {...props} displayLeftArrow={false} displayRightArrow={true} />)
    expect(rightButton.matches(':focus')).toBe(true)
  })

  test('left button is not disabled', function () {
    subject({...props, ...{displayLeftArrow: true, disabled: false}})
    expect(screen.getByRole('button', {name: 'Previous'})).not.toBeDisabled()
  })

  test('right button is not disabled', function () {
    subject({...props, ...{displayRightArrow: true, disabled: false}})
    expect(screen.getByRole('button', {name: 'Next'})).not.toBeDisabled()
  })

  test('left button can be disabled', function () {
    subject({...props, ...{displayLeftArrow: true, disabled: true}})
    expect(screen.getByRole('button', {name: 'Previous'})).toBeDisabled()
  })

  test('right button is disabled', function () {
    subject({...props, ...{displayRightArrow: true, disabled: true}})
    expect(screen.getByRole('button', {name: 'Next'})).toBeDisabled()
  })

  test('adds a VO description for the left arrow button', function () {
    subject({...props, ...{displayLeftArrow: true, leftArrowDescription: 'Previous record'}})
    expect(screen.getByText('Previous record')).toBeInTheDocument()
  })

  test('adds a VO description for the right arrow button', function () {
    subject({...props, ...{displayRightArrow: true, rightArrowDescription: 'Next record'}})
    expect(screen.getByText('Next record')).toBeInTheDocument()
  })
})
