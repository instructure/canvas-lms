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
import {render, fireEvent} from '@testing-library/react'
import React from 'react'
import MentionDropdownOption from '../MentionDropdownOption'

const setup = props => {
  return render(<MentionDropdownOption name="Davis Hyer" {...props} />)
}

describe('MentionDropdownOption tests', () => {
  it('should render', () => {
    const {getByText} = setup()
    expect(getByText('Davis Hyer')).toBeTruthy()
  })

  it('should add aria-selected when isSelected prop is true', () => {
    const {container} = setup({isSelected: true})
    const optionElement = container.querySelector('[aria-selected="true"]')
    expect(optionElement).toBeTruthy()
  })

  it('should add a data-ignore-a11y-check attribute on all content nodes within the mention option', () => {
    const {container, getByText} = setup()
    const img = container.querySelector('img')
    const initialText = getByText(/dh/i)
    const nameText = getByText(/davis hyer/i)
    expect(img).toHaveAttribute('data-ignore-a11y-check')
    expect(initialText).toHaveAttribute('data-ignore-a11y-check')
    expect(nameText).toHaveAttribute('data-ignore-a11y-check')
  })

  it('should add a data-ignore-wordcount to the non img content nodes within the mention option', () => {
    const {getByText} = setup()
    const initialText = getByText(/dh/i)
    const nameText = getByText(/davis hyer/i)
    expect(initialText).toHaveAttribute('data-ignore-wordcount', 'chars-only')
    expect(nameText).toHaveAttribute('data-ignore-wordcount')
  })

  it('should call onSelect when selected', () => {
    const selectSpy = jest.fn()
    const {container} = setup({onSelect: selectSpy})
    fireEvent.click(container.querySelector('li'))
    expect(selectSpy.mock.calls.length).toBe(1)
  })
})
