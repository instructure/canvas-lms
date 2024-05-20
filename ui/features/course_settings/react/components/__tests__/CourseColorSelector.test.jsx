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
import {fireEvent, render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'

import CourseColorSelector, {COLOR_OPTIONS} from '../CourseColorSelector'

const keyDown = keyCode => {
  fireEvent.keyDown(document.activeElement, {keyCode})
}

describe('CourseColorSelector', () => {
  it('renders a text box with the current course color', () => {
    const {getByLabelText} = render(<CourseColorSelector courseColor="#fab" />)
    const textBox = getByLabelText('Set course color to a custom hexadecimal code')

    expect(textBox).toBeInTheDocument()
    expect(textBox.value).toBe('#fab')
  })

  it('renders a text box with a blank value if no course color is selected', () => {
    const {getByLabelText} = render(<CourseColorSelector />)
    const textBox = getByLabelText('Set course color to a custom hexadecimal code')

    expect(textBox.value).toBe('')
  })

  it('renders a preview of the entered color inside the text box', () => {
    const {getByTestId} = render(<CourseColorSelector courseColor="#bad" />)
    const colorPreview = getByTestId('course-color-preview')

    expect(colorPreview).toBeInTheDocument()
    expect(colorPreview.style.getPropertyValue('background-color')).toBe('rgb(187, 170, 221)')
  })

  it('rejects typed non-hex code characters and supplies a starting # if none is typed', async () => {
    const {getByLabelText} = render(<CourseColorSelector />)
    const textBox = getByLabelText('Set course color to a custom hexadecimal code')

    await userEvent.type(textBox, '1.?g-5*typo9Ae!@#lqb98765432')
    expect(textBox.value).toBe('#159Aeb')
  })

  it('allows the leading pound sign to be deleted', async () => {
    const {getByLabelText} = render(<CourseColorSelector />)
    const textBox = getByLabelText('Set course color to a custom hexadecimal code')

    await userEvent.type(textBox, 'abc{backspace}{backspace}{backspace}{backspace}')
    expect(textBox.value).toBe('')
  })

  describe('ColorOptions', () => {
    it('renders a set of buttons for preset colors', () => {
      const {getAllByRole} = render(<CourseColorSelector />)
      const presetButtons = getAllByRole('button')

      expect(presetButtons.length).toBe(15)
    })

    it('renders screenreader-only instructions for how to navigate the preset buttons', () => {
      const {getByText} = render(<CourseColorSelector />)
      const instructions = getByText(
        'Set course color to a preset hexadecimal color code. Use the left and right arrow keys to navigate presets.'
      )

      expect(instructions).toBeInTheDocument()
    })

    it('shows a preset button as selected if it matches the color in the text box', () => {
      const {getByRole} = render(<CourseColorSelector courseColor="#614C98" />)
      const selectedButton = getByRole('button', {pressed: true})
      const selectedIcon = selectedButton.querySelector('svg[name="IconCheckMark"]')

      expect(selectedButton).toBeInTheDocument()
      expect(selectedButton.id).toBe('color-#614C98')
      expect(selectedIcon).toBeInTheDocument()
    })

    it('does not show any buttons as selected if the color in the text box does not match any presets', () => {
      const {container, queryByRole} = render(<CourseColorSelector courseColor="#fab" />)
      const selectedButton = queryByRole('button', {pressed: true})
      const selectedIcon = container.querySelector('svg[name="IconCheckMark"]')

      expect(selectedButton).not.toBeInTheDocument()
      expect(selectedIcon).not.toBeInTheDocument()
    })

    it('only allows tab navigation to the selected preset or last focused preset', async () => {
      render(<CourseColorSelector courseColor="#CC7D2D" />)

      // Focus should move to the selected color
      await userEvent.tab()
      expect(document.activeElement.id).toBe('color-#CC7D2D')

      // Then should skip the remaining colors and go directly to the input text box
      await userEvent.tab()
      expect(document.activeElement.tagName).toBe('INPUT')
    })

    it('allows navigating presets with left and right arrow keys when one is focused', async () => {
      render(<CourseColorSelector courseColor="#bad" />)

      // Focus should start at the first preset if none are selected
      await userEvent.tab()
      expect(document.activeElement.id).toBe(`color-${COLOR_OPTIONS[0]}`)

      // Focus should wrap to the last preset if the user navigates left from the first
      keyDown(37)
      expect(document.activeElement.id).toBe(`color-${COLOR_OPTIONS[COLOR_OPTIONS.length - 1]}`)

      // Focus should wrap to the first preset if the user navigates right from the last
      keyDown(39)
      expect(document.activeElement.id).toBe(`color-${COLOR_OPTIONS[0]}`)

      // Focus should proceed in the order of the presets
      keyDown(39)
      keyDown(39)
      keyDown(39)
      expect(document.activeElement.id).toBe(`color-${COLOR_OPTIONS[3]}`)

      // Focus should return to the last focused preset when tabbing back and forth
      await userEvent.tab()
      expect(document.activeElement.tagName).toBe('INPUT')
      await userEvent.tab({shift: true})
      expect(document.activeElement.id).toBe(`color-${COLOR_OPTIONS[3]}`)
    })
  })
})
