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
import {render, fireEvent, waitFor, within} from '@testing-library/react'
import ProficiencyTable from '../ProficiencyTable'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(() => vi.fn(() => {})),
}))

const defaultProps = (props = {}) => ({
  update: () => Promise.resolve(),
  contextType: 'Account',
  ...props,
})

describe('default proficiency', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

  it('renders the correct headers', () => {
    const {getByText} = render(<ProficiencyTable {...defaultProps()} />)
    expect(getByText('Mastery')).not.toBeNull()
    expect(getByText('Description')).not.toBeNull()
    expect(getByText('Points')).not.toBeNull()
    expect(getByText('Color')).not.toBeNull()
  })

  it('renders five ratings', () => {
    const {getAllByLabelText} = render(<ProficiencyTable {...defaultProps()} />)
    const inputs = getAllByLabelText(/Change description/)
    expect(inputs).toHaveLength(5)
  })

  it('clicking button adds rating', () => {
    const {getByText, getAllByLabelText} = render(<ProficiencyTable {...defaultProps()} />)
    const button = getByText(/Add Mastery Level/)
    fireEvent.click(button)
    const inputs = getAllByLabelText(/Change description/)
    expect(inputs).toHaveLength(6)
  })

  it('clicking add rating button flashes SR message', () => {
    const {getByText} = render(<ProficiencyTable {...defaultProps()} />)
    const button = getByText(/Add Mastery Level/)
    fireEvent.click(button)
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'Added mastery level',
      type: 'success',
      srOnly: true,
    })
  })

  it('handling delete rating removes rating and flashes SR message', () => {
    const {getAllByText, getByText} = render(<ProficiencyTable {...defaultProps()} />)
    fireEvent.click(getAllByText(/Delete mastery level/)[0])
    fireEvent.click(getByText(/Confirm/))
    expect(showFlashAlert).toHaveBeenCalledWith({
      message: 'Mastery level deleted',
      type: 'success',
      srOnly: true,
    })
  })

  it('setting blank description sets error and focus', async () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps()} />)
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: ''}})
    fireEvent.click(getByText('Save Mastery Scale'))
    const error = await within(masteryField.closest('.description')).findByText(
      'Missing required description',
    )
    expect(error).not.toBeNull()
    expect(document.activeElement).toEqual(masteryField.closest('input'))
  })

  it('setting blank points sets error and focus', async () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps()} />)
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: ''}})
    fireEvent.click(getByText('Save Mastery Scale'))
    const error = await within(pointsInput.closest('.points')).findByText('Invalid points')
    expect(error).not.toBeNull()
    expect(document.activeElement).toEqual(pointsInput.closest('input'))
  })

  it('setting invalid points sets error and focus', async () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps()} />)
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '1.1.1'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    const error = await within(pointsInput.closest('.points')).findByText('Invalid points')
    expect(error).not.toBeNull()
    expect(document.activeElement).toEqual(pointsInput.closest('input'))
  })

  it('setting negative points sets error and focus', async () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps()} />)
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '-1'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    const error = await within(pointsInput.closest('.points')).findByText('Negative points')
    expect(error).not.toBeNull()
    expect(document.activeElement).toEqual(pointsInput.closest('input'))
  })

  it('setting duplicate point values sets error and focus', async () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps()} />)
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '4'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    const error = await within(pointsInput.closest('.points')).findByText('Points must be unique')
    expect(error).not.toBeNull()
    expect(document.activeElement).toEqual(pointsInput.closest('input'))
  })

  it('only sets focus on the first error', () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps()} />)
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: ''}})
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '-1'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(document.activeElement).toEqual(masteryField.closest('input'))
  })

  it('renders confirmation modal, calls update on save, and flashes a message to the user', async () => {
    const updateSpy = vi.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps({contextType: 'course'})} update={updateSpy} />,
    )
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: 'Mastery2'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    fireEvent.click(getByText('Save'))
    await waitFor(() => {
      expect(updateSpy).toHaveBeenCalled()
      expect(showFlashAlert).toHaveBeenCalledWith({
        message: 'Mastery scale saved',
        type: 'success',
      })
    })
  })

  it('does not call save when canceling on the confirmation modal', async () => {
    const updateSpy = vi.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />,
    )
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: 'Mastery2'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    fireEvent.click(getByText('Cancel'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('empty rating description does not call update', () => {
    const updateSpy = vi.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />,
    )
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: ''}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('empty rating points does not call update', () => {
    const updateSpy = vi.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />,
    )
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: ''}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('invalid rating points does not call update', () => {
    const updateSpy = vi.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />,
    )
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '1.1.1'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('increasing rating points does call update', () => {
    const updateSpy = vi.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />,
    )
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '1000'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    fireEvent.click(getByText('Save'))
    expect(updateSpy).toHaveBeenCalled()
  })

  it('negative rating points does not call update', () => {
    const updateSpy = vi.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />,
    )
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '-10'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('save button is initially disabled', () => {
    const {getByText} = render(<ProficiencyTable {...defaultProps()} />)
    const saveButton = getByText('Save Mastery Scale').closest('button')
    expect(saveButton.disabled).toEqual(true)
  })

  it('save errors do not disable the save button', () => {
    const {getByText, getByDisplayValue} = render(<ProficiencyTable {...defaultProps()} />)

    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '100'}})
    fireEvent.click(getByText('Save Mastery Scale'))

    const saveButton = getByText('Save Mastery Scale').closest('button')
    expect(saveButton.disabled).toEqual(false)
  })

  it('calls onNotifyPendingChanges when changes data', async () => {
    const onNotifyPendingChangesSpy = vi.fn()
    const update = () => Promise.resolve()
    const {getByText, getByDisplayValue} = render(
      <ProficiencyTable
        {...defaultProps()}
        onNotifyPendingChanges={onNotifyPendingChangesSpy}
        update={update}
      />,
    )

    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '100'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    fireEvent.click(getByText('Save'))

    await waitFor(() => {
      expect(onNotifyPendingChangesSpy.mock.calls).toHaveLength(2)
      // first call first argument
      expect(onNotifyPendingChangesSpy.mock.calls[0][0]).toBe(true)
      // second call first argument
      expect(onNotifyPendingChangesSpy.mock.calls[1][0]).toBe(false)
    })
  })
})
