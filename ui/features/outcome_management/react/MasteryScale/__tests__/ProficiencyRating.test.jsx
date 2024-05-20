// @vitest-environment jsdom
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

import React from 'react'
import {render, fireEvent} from '@testing-library/react'
import ProficiencyRating from '../ProficiencyRating'
import userEvent from '@testing-library/user-event'

describe('ProficiencyRating', () => {
  let onDeleteMock
  let onFocusChangeMock
  let onMasteryChangeMock
  let onDescriptionChangeMock
  let onPointsChangeMock

  const defaultProps = (props = {}) => ({
    color: '00ff00',
    description: 'Stellar',
    disableDelete: false,
    mastery: false,
    canManage: false,
    onColorChange: () => {},
    onDelete: onDeleteMock,
    onDescriptionChange: onDescriptionChangeMock,
    onFocusChange: onFocusChangeMock,
    onMasteryChange: onMasteryChangeMock,
    onPointsChange: onPointsChangeMock,
    points: '10.0',
    position: 1,
    ...props,
  })

  const renderProficiencyRating = (props = {}) =>
    render(<ProficiencyRating {...defaultProps(props)} />)

  beforeEach(() => {
    onDeleteMock = jest.fn()
    onFocusChangeMock = jest.fn()
    onMasteryChangeMock = jest.fn()
    onDescriptionChangeMock = jest.fn()
    onPointsChangeMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('can not manage', () => {
    it('renders the ProficiencyRating component', () => {
      const wrapper = renderProficiencyRating()

      expect(wrapper.container).toMatchSnapshot()
    })

    it('mastery checkbox is checked if mastery', () => {
      const wrapper = renderProficiencyRating({mastery: true})
      const radio = wrapper.getByRole('radio')

      expect(radio.checked).toBe(true)
    })

    it('mastery checkbox does not appear if not mastery', () => {
      const wrapper = renderProficiencyRating()
      const radio = wrapper.container.querySelector('input')

      expect(radio).not.toBeInTheDocument()
    })

    it('mastery checkbox does not receive focus', () => {
      const wrapper = renderProficiencyRating({focusField: 'mastery', mastery: true})
      const radio = wrapper.getByRole('radio')

      expect(radio).not.toBe(document.activeElement)
    })

    it('clicking mastery checkbox does not trigger change', async () => {
      const wrapper = renderProficiencyRating({mastery: true})
      const radio = wrapper.container.querySelector('input')

      await userEvent.click(radio)

      expect(onMasteryChangeMock).not.toHaveBeenCalled()
    })

    it('does not render TextInput', () => {
      const wrapper = renderProficiencyRating()
      const input = wrapper.container.querySelector('input')

      expect(input).not.toBeInTheDocument()
    })

    it('does not render delete button', () => {
      const wrapper = renderProficiencyRating()
      const button = wrapper.container.querySelector('button')

      expect(button).not.toBeInTheDocument()
    })

    it('includes the points', () => {
      const wrapper = renderProficiencyRating()
      const content = wrapper.getByText('10')

      expect(content).toBeInTheDocument()
    })
  })

  describe('can manage', () => {
    it('renders the ProficiencyRating component', () => {
      const wrapper = renderProficiencyRating({canManage: true})

      expect(wrapper.container).toBeInTheDocument()
    })

    it('mastery checkbox is checked if mastery', () => {
      const wrapper = renderProficiencyRating({mastery: true, canManage: true})
      const radio = wrapper.getByRole('radio')

      expect(radio.checked).toBe(true)
    })

    it('clicking mastery checkbox triggers change', async () => {
      const wrapper = renderProficiencyRating({canManage: true})
      const radio = wrapper.getByRole('radio')

      await userEvent.click(radio)

      expect(onMasteryChangeMock).toHaveBeenCalledTimes(1)
    })

    it('includes the rating description', () => {
      const wrapper = renderProficiencyRating({canManage: true})
      const input = wrapper.getByDisplayValue('Stellar')

      expect(input).toBeInTheDocument()
    })

    it('changing description triggers change', () => {
      const wrapper = renderProficiencyRating({canManage: true})
      const input = wrapper.getByDisplayValue('Stellar')

      fireEvent.change(input, {target: {value: 'some new value'}})

      expect(onDescriptionChangeMock).toHaveBeenCalledTimes(1)
    })

    it('includes the points', () => {
      const wrapper = renderProficiencyRating({canManage: true})
      const content = wrapper.getByDisplayValue('10')

      expect(content).toBeInTheDocument()
    })

    it('changing points triggers change', () => {
      const {getAllByRole} = renderProficiencyRating({canManage: true})
      const secondInput = getAllByRole('textbox')[1]

      fireEvent.change(secondInput, {target: {value: 'some new value'}})

      expect(onPointsChangeMock).toHaveBeenCalledTimes(1)
    })

    it('calls onDelete prop when click on delete and confirm in the confirmation modal', () => {
      const {getByText} = renderProficiencyRating({canManage: true})

      fireEvent.click(getByText('Delete mastery level 1'))
      fireEvent.click(getByText('Confirm'))

      expect(onDeleteMock).toHaveBeenCalledTimes(1)
    })

    it('clicking disabled delete button does not show delete modal', async () => {
      const {queryByText} = renderProficiencyRating({
        disableDelete: true,
        canManage: true,
      })

      await userEvent.click(queryByText('Delete mastery level 1'))

      expect(queryByText('Remove Mastery Level')).not.toBeInTheDocument()
    })

    it('shows color input', () => {
      const {getByText} = renderProficiencyRating({canManage: true})

      expect(getByText('Change color for mastery level 1')).toBeInTheDocument()
    })

    it('calls onFocusChange prop when current input looses focus', () => {
      const wrapper = renderProficiencyRating({canManage: true})

      fireEvent.blur(wrapper.getByDisplayValue('Stellar'))
      fireEvent.blur(wrapper.getByDisplayValue('10'))

      expect(onFocusChangeMock).toHaveBeenCalledTimes(2)
    })

    describe('when individualOutcome is true', () => {
      it('hides color input', () => {
        const {queryByText, container} = renderProficiencyRating({
          canManage: true,
          individualOutcome: true,
        })

        expect(queryByText('Change color for mastery level 1')).not.toBeInTheDocument()
        expect(container.getElementsByClassName('color').length).toBe(0)
      })
    })
  })
})
