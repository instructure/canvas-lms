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
import $ from 'jquery'
import React from 'react'
import {render, fireEvent, wait, within} from '@testing-library/react'
import ProficiencyTable from '../ProficiencyTable'

const defaultProps = {
  update: () => Promise.resolve()
}

describe('default proficiency', () => {
  let flashMock
  beforeEach(() => {
    flashMock = jest.spyOn($, 'screenReaderFlashMessage')
  })

  afterEach(() => {
    flashMock.mockRestore()
  })

  it('renders the ProficiencyRating component', () => {
    const {getByText} = render(<ProficiencyTable {...defaultProps} />)
    expect(getByText('Proficiency Rating')).not.toBeNull()
  })

  it('renders five ratings', () => {
    const {getAllByLabelText} = render(<ProficiencyTable {...defaultProps} />)
    const inputs = getAllByLabelText(/Change description/)
    expect(inputs.length).toEqual(5)
  })

  it('sets focus on mastery on first row only', async () => {
    const {getAllByLabelText} = render(<ProficiencyTable {...defaultProps} />)
    const inputs = getAllByLabelText(/Change mastery/)
    const firstMastery = inputs[0]
    await wait(() => expect(document.activeElement).toEqual(firstMastery))
  })

  it('clicking button adds rating', () => {
    const {getByText, getAllByLabelText} = render(<ProficiencyTable {...defaultProps} />)
    const button = getByText(/Add proficiency rating/)
    fireEvent.click(button)
    const inputs = getAllByLabelText(/Change description/)
    expect(inputs.length).toEqual(6)
  })

  it('clicking add rating button flashes SR message', () => {
    const {getByText} = render(<ProficiencyTable {...defaultProps} />)
    const button = getByText(/Add proficiency rating/)
    fireEvent.click(button)
    expect(flashMock).toHaveBeenCalledTimes(1)
  })

  it('handling delete rating removes rating and flashes SR message', () => {
    const {getAllByText} = render(<ProficiencyTable {...defaultProps} />)
    const button = getAllByText(/Delete proficiency rating/)[0]
    fireEvent.click(button)
    expect(flashMock).toHaveBeenCalledTimes(1)
  })

  it('setting blank description sets error and focus', async () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps} />)
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: ''}})
    fireEvent.click(getByText('Save Mastery Scale'))
    const error = await within(masteryField.closest('td')).findByText(
      'Missing required description'
    )
    expect(error).not.toBeNull()
    expect(document.activeElement).toEqual(masteryField.closest('input'))
  })

  it('setting blank points sets error and focus', async () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps} />)
    const row = getByDisplayValue('Mastery').closest('tr')
    const pointsInput = within(row).getByLabelText(/Change points/)
    fireEvent.change(pointsInput, {target: {value: ''}})
    fireEvent.click(getByText('Save Mastery Scale'))
    const error = await within(row).findByText('Invalid points')
    expect(error).not.toBeNull()
    expect(document.activeElement).toEqual(pointsInput.closest('input'))
  })

  it('setting invalid points sets error and focus', async () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps} />)
    const row = getByDisplayValue('Mastery').closest('tr')
    const pointsInput = within(row).getByLabelText(/Change points/)
    fireEvent.change(pointsInput, {target: {value: '1.1.1'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    const error = await within(row).findByText('Invalid points')
    expect(error).not.toBeNull()
    expect(document.activeElement).toEqual(pointsInput.closest('input'))
  })

  it('setting negative points sets error and focus', async () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps} />)
    const row = getByDisplayValue('Mastery').closest('tr')
    const pointsInput = within(row).getByLabelText(/Change points/)
    fireEvent.change(pointsInput, {target: {value: '-1'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    const error = await within(row).findByText('Negative points')
    expect(error).not.toBeNull()
    expect(document.activeElement).toEqual(pointsInput.closest('input'))
  })

  it('only sets focus on the first error', () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps} />)
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: ''}})
    const pointsInput = within(masteryField.closest('tr')).getByLabelText(/Change points/)
    fireEvent.change(pointsInput, {target: {value: '-1'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(document.activeElement).toEqual(masteryField.closest('input'))
  })

  it('calls update on save', async () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps} update={updateSpy} />
    )
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: 'Mastery2'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).toHaveBeenCalled()
  })

  it('empty rating description does not call update', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps} update={updateSpy} />
    )
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: ''}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('empty rating points does not call update', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps} update={updateSpy} />
    )
    const row = getByDisplayValue('Mastery').closest('tr')
    const pointsInput = within(row).getByLabelText(/Change points/)
    fireEvent.change(pointsInput, {target: {value: ''}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('invalid rating points does not call update', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps} update={updateSpy} />
    )
    const row = getByDisplayValue('Mastery').closest('tr')
    const pointsInput = within(row).getByLabelText(/Change points/)
    fireEvent.change(pointsInput, {target: {value: '1.1.1'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('increasing rating points does not call update', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps} update={updateSpy} />
    )
    const row = getByDisplayValue('Mastery').closest('tr')
    const pointsInput = within(row).getByLabelText(/Change points/)
    fireEvent.change(pointsInput, {target: {value: '1000'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('negative rating points does not call update', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps} update={updateSpy} />
    )
    const row = getByDisplayValue('Mastery').closest('tr')
    const pointsInput = within(row).getByLabelText(/Change points/)
    fireEvent.change(pointsInput, {target: {value: '-10'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('save button is initially disabled', () => {
    const {getByText} = render(<ProficiencyTable {...defaultProps} />)
    const saveButton = getByText('Save Mastery Scale').closest('button')
    expect(saveButton.disabled).toEqual(true)
  })
})

describe('custom proficiency', () => {
  it('renders two ratings that are deletable', () => {
    const customProficiencyProps = {
      ...defaultProps,
      proficiency: {
        proficiencyRatingsConnection: {
          nodes: [
            {
              description: 'Great',
              points: 10,
              color: '0000ff',
              mastery: true
            },
            {
              description: 'Poor',
              points: 0,
              color: 'ff0000',
              mastery: false
            }
          ]
        }
      }
    }
    const {getAllByText} = render(<ProficiencyTable {...customProficiencyProps} />)
    const deleteButtons = getAllByText(/Delete proficiency rating/).map(el => el.closest('button'))
    expect(deleteButtons.length).toEqual(2)
    expect(deleteButtons.some(btn => btn.disabled)).toEqual(false)
  })

  it('renders one rating that is not deletable', () => {
    const props = {
      ...defaultProps,
      proficiency: {
        proficiencyRatingsConnection: {
          nodes: [
            {
              description: 'Uno',
              points: 1,
              color: '0000ff',
              mastery: true
            }
          ]
        }
      }
    }
    const {getAllByText} = render(<ProficiencyTable {...props} />)
    const deleteButtons = getAllByText(/Delete proficiency rating/).map(el => el.closest('button'))
    expect(deleteButtons.length).toEqual(1)
    expect(deleteButtons[0].disabled).toEqual(true)
  })
})
