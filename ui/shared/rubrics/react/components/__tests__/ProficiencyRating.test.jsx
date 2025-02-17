/*
 * Copyright (C) 2018 - present Instructure, Inc.
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

/*
  TODO: Duplicated and modified within jsx/outcomes/MasteryScale for use there
        Remove when feature flag account_level_mastery_scales is enabled
*/

import React from 'react'
import {render, cleanup, fireEvent} from '@testing-library/react'
import ProficiencyRating from '../ProficiencyRating'
import {userEvent} from '@testing-library/user-event'

const defaultProps = (props = {}) => ({
  color: '00ff00',
  description: 'Stellar',
  disableDelete: false,
  mastery: false,
  onColorChange: () => {},
  onDelete: () => {},
  onDescriptionChange: () => {},
  onMasteryChange: () => {},
  onPointsChange: () => {},
  onBlurChange: () => {},
  points: '10.0',
  ...props,
})

const renderProficiencyRating = (props = {}) =>
  render(
    <span>
      <span>
        <ProficiencyRating {...defaultProps(props)} />
      </span>
    </span>,
  )

describe('ProficiencyRating', () => {
  afterEach(() => {
    cleanup()
  })

  it('renders the ProficiencyRating component', () => {
    const wrapper = renderProficiencyRating()

    expect(wrapper.container).toBeInTheDocument()
  })

  it('mastery checkbox is checked if mastery', () => {
    const wrapper = renderProficiencyRating({
      mastery: true,
    })

    const radio = wrapper.container.querySelector('input[checked]')

    expect(radio).toBeInTheDocument()
  })

  describe('focus handling', () => {
    let containerElement = null
    let wrapper = null

    beforeEach(() => {
      containerElement = document.createElement('div')
      document.body.appendChild(containerElement)
    })

    afterEach(() => {
      if (wrapper) wrapper.unmount()
      document.body.removeChild(containerElement)
    })

    it('mastery checkbox receives focus', () => {
      wrapper = renderProficiencyRating({focusField: 'mastery'})

      expect(document.activeElement).toBe(wrapper.container.querySelector('input'))
    })
  })

  it('clicking mastery checkbox triggers change', async () => {
    const onMasteryChange = jest.fn()
    const wrapper = renderProficiencyRating({onMasteryChange})

    await userEvent.click(wrapper.container.querySelector('input'))

    expect(onMasteryChange).toHaveBeenCalledTimes(1)
  })

  it('includes the rating description', () => {
    const wrapper = renderProficiencyRating()
    const input = wrapper.container.querySelector('input[value="Stellar"]')

    expect(input).toBeInTheDocument()
  })

  it('changing description triggers change', async () => {
    const onDescriptionChange = jest.fn()
    const wrapper = renderProficiencyRating({onDescriptionChange})

    await userEvent.type(wrapper.container.querySelector('input[value="Stellar"]'), 'c')

    expect(onDescriptionChange).toHaveBeenCalledTimes(1)
  })

  it('includes the points', () => {
    const wrapper = renderProficiencyRating()
    const input = wrapper.container.querySelectorAll('input')[2]

    expect(input.value).toEqual('10')
  })

  it('changing points triggers change', async () => {
    const onPointsChange = jest.fn()
    const wrapper = renderProficiencyRating({onPointsChange})

    await userEvent.type(wrapper.container.querySelector('input[value="10"]'), 'c')

    expect(onPointsChange).toHaveBeenCalledTimes(1)
  })

  it('clicking delete button triggers delete', async () => {
    const onDelete = jest.fn()
    const wrapper = renderProficiencyRating({onDelete})

    await userEvent.click(wrapper.container.querySelector('.delete button'))

    expect(onDelete).toHaveBeenCalledTimes(1)
  })

  it('clicking disabled delete button does not triggers delete', async () => {
    const onDelete = jest.fn()
    const wrapper = renderProficiencyRating({
      onDelete,
      disableDelete: true,
    })

    await userEvent.click(wrapper.container.querySelector('.delete button'))

    expect(onDelete).toHaveBeenCalledTimes(0)
  })

  it('calls onBlurChange with correct parameters when description input loses focus', async () => {
    const onBlurChange = jest.fn()
    const wrapper = renderProficiencyRating({ onBlurChange })

    const descriptionInput = wrapper.container.querySelector('input[value="Stellar"]')
    fireEvent.blur(descriptionInput)
    expect(onBlurChange).toHaveBeenCalledWith('Stellar', 'description')
  })

  it('calls onBlurChange with correct parameters when points input loses focus', () => {
    const onBlurChange = jest.fn()
    const wrapper = renderProficiencyRating({ onBlurChange })

    const pointsInput = wrapper.container.querySelectorAll('input')[2]
    fireEvent.blur(pointsInput)

    expect(onBlurChange).toHaveBeenCalledWith('10', 'points')
  })

  it('shows error message when description input is empty and loses focus', () => {
    const onBlurChange = jest.fn();
    const wrapper = renderProficiencyRating({ onBlurChange, descriptionError: 'Description is required' })

    const descriptionInput = wrapper.container.querySelector('input[value="Stellar"]')
    fireEvent.change(descriptionInput, { target: { value: '' } })
    fireEvent.blur(descriptionInput)

    expect(onBlurChange).toHaveBeenCalledWith('', 'description')
    expect(wrapper.container).toHaveTextContent('Description is required')
  })

  it('shows error message when points input is empty and loses focus', () => {
    const onBlurChange = jest.fn();
    const wrapper = renderProficiencyRating({ onBlurChange, pointsError: 'Invalid points' })

    const pointsInput = wrapper.container.querySelector('input[value="10"]')
    fireEvent.change(pointsInput, { target: { value: '' } })
    fireEvent.blur(pointsInput)

    expect(onBlurChange).toHaveBeenCalledWith('', 'points')
    expect(wrapper.container).toHaveTextContent('Invalid points')
  });
})
