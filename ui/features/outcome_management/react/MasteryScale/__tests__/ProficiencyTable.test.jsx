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

jest.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: jest.fn(() => jest.fn(() => {})),
}))

const defaultProps = (props = {}) => ({
  update: () => Promise.resolve(),
  contextType: 'Account',
  ...props,
})

describe('default proficiency', () => {
  afterEach(() => {
    jest.clearAllMocks()
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
    expect(inputs.length).toEqual(5)
  })

  it('clicking button adds rating', () => {
    const {getByText, getAllByLabelText} = render(<ProficiencyTable {...defaultProps()} />)
    const button = getByText(/Add Mastery Level/)
    fireEvent.click(button)
    const inputs = getAllByLabelText(/Change description/)
    expect(inputs.length).toEqual(6)
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
      'Missing required description'
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
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps({contextType: 'course'})} update={updateSpy} />
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
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />
    )
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: 'Mastery2'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    fireEvent.click(getByText('Cancel'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('empty rating description does not call update', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />
    )
    const masteryField = getByDisplayValue('Mastery')
    fireEvent.change(masteryField, {target: {value: ''}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('empty rating points does not call update', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />
    )
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: ''}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('invalid rating points does not call update', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />
    )
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '1.1.1'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(updateSpy).not.toHaveBeenCalled()
  })

  it('increasing rating points does call update', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />
    )
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '1000'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    fireEvent.click(getByText('Save'))
    expect(updateSpy).toHaveBeenCalled()
  })

  it('negative rating points does not call update', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} update={updateSpy} />
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
    const onNotifyPendingChangesSpy = jest.fn()
    const update = () => Promise.resolve()
    const {getByText, getByDisplayValue} = render(
      <ProficiencyTable
        {...defaultProps()}
        onNotifyPendingChanges={onNotifyPendingChangesSpy}
        update={update}
      />
    )

    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '100'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    fireEvent.click(getByText('Save'))

    await waitFor(() => {
      expect(onNotifyPendingChangesSpy.mock.calls.length).toBe(2)
      // first call first argument
      expect(onNotifyPendingChangesSpy.mock.calls[0][0]).toBe(true)
      // second call first argument
      expect(onNotifyPendingChangesSpy.mock.calls[1][0]).toBe(false)
    })
  })
})

describe('custom proficiency', () => {
  it('renders two ratings that are deletable', () => {
    const customProficiencyProps = {
      ...defaultProps(),
      proficiency: {
        proficiencyRatingsConnection: {
          nodes: [
            {
              description: 'Great',
              points: 10,
              color: '0000ff',
              mastery: true,
            },
            {
              description: 'Poor',
              points: 0,
              color: 'ff0000',
              mastery: false,
            },
          ],
        },
      },
    }
    const {getAllByText} = render(<ProficiencyTable {...customProficiencyProps} />)
    const deleteButtons = getAllByText(/Delete mastery level/).map(el => el.closest('button'))
    expect(deleteButtons.length).toEqual(2)
    expect(deleteButtons.some(btn => btn.disabled)).toEqual(false)
  })

  describe('ratings are automatically sorted', () => {
    const updateSpy = jest.fn(() => Promise.resolve())
    const defaultColor = 'EF4437'
    const defaultRating1 = {
      description: 'Great',
      points: 10,
      color: '0000ff',
      mastery: false,
    }
    const defaultRating2 = {
      description: 'Average',
      points: 5,
      color: '00ff00',
      mastery: true,
    }
    const defaultRating3 = {
      description: 'Poor',
      points: 3,
      color: 'ff0000',
      mastery: false,
    }
    const customProficiencyProps = {
      ...defaultProps(),
      proficiency: {
        proficiencyRatingsConnection: {
          nodes: [defaultRating1, defaultRating2, defaultRating3],
        },
      },
    }

    it('by point value when a new rating is added', () => {
      const {getAllByLabelText, getByText, getByDisplayValue} = render(
        <ProficiencyTable {...customProficiencyProps} update={updateSpy} />
      )
      const button = getByText(/Add Mastery Level/)
      fireEvent.click(button)

      const pointsInput = getByDisplayValue('2')
      const descriptionInput = getAllByLabelText(/Change description/)[3]

      fireEvent.change(pointsInput, {target: {value: '9'}})
      fireEvent.change(descriptionInput, {target: {value: 'Almost Perfect'}})
      fireEvent.click(getByText('Save Mastery Scale'))
      fireEvent.click(getByText('Save'))

      const proficiencyDescriptions = getAllByLabelText(/Change description/).map(el => el.value)
      const proficiencyPoints = getAllByLabelText(/Change points/).map(el => el.value)

      const sortedDescriptions = ['Great', 'Almost Perfect', 'Average', 'Poor']
      const sortedPoints = ['10', '9', '5', '3']

      expect(proficiencyDescriptions).toEqual(sortedDescriptions)
      expect(proficiencyPoints).toEqual(sortedPoints)

      const addedRating = {
        description: 'Almost Perfect',
        points: 9,
        color: defaultColor,
        mastery: false,
      }
      const expectedRatings = [defaultRating1, addedRating, defaultRating2, defaultRating3]
      expect(updateSpy).toHaveBeenCalledWith({ratings: expectedRatings})

      const saveButton = getByText('Save Mastery Scale').closest('button')
      expect(saveButton.disabled).toEqual(true)
    })

    it('masteryIndex is incremented when sorting causes a rating to be put above the current mastery', () => {
      const {getAllByLabelText, getByText, getByDisplayValue} = render(
        <ProficiencyTable {...customProficiencyProps} update={updateSpy} />
      )

      const pointsInput = getByDisplayValue('3')
      fireEvent.change(pointsInput, {target: {value: '20'}})
      fireEvent.click(getByText('Save Mastery Scale'))
      fireEvent.click(getByText('Save'))

      const masteryRatings = getAllByLabelText(/Mastery.*for mastery level/).map(el => el.checked)
      const expectedMasteryRatings = [false, false, true]
      expect(masteryRatings).toEqual(expectedMasteryRatings)

      const updatedRating = {...defaultRating3}
      updatedRating.points = 20
      const expectedRatings = [updatedRating, defaultRating1, defaultRating2]
      expect(updateSpy).toHaveBeenCalledWith({ratings: expectedRatings})

      const saveButton = getByText('Save Mastery Scale').closest('button')
      expect(saveButton.disabled).toEqual(true)
    })

    it('masteryIndex is not incremented when adding a new rating that is less than the current mastery', () => {
      const {getAllByLabelText, getByText} = render(
        <ProficiencyTable {...customProficiencyProps} update={updateSpy} />
      )
      const button = getByText(/Add Mastery Level/)
      fireEvent.click(button)

      const descriptionInput = getAllByLabelText(/Change description/)[3]
      fireEvent.change(descriptionInput, {target: {value: 'Pretty Poor'}})
      fireEvent.click(getByText('Save Mastery Scale'))
      fireEvent.click(getByText('Save'))

      const masteryRatings = getAllByLabelText(/Mastery.*for mastery level/).map(el => el.checked)
      const expectedMasteryRatings = [false, true, false, false]
      expect(masteryRatings).toEqual(expectedMasteryRatings)

      const addedRating = {
        description: 'Pretty Poor',
        points: 2,
        color: defaultColor,
        mastery: false,
      }
      const expectedRatings = [defaultRating1, defaultRating2, defaultRating3, addedRating]
      expect(updateSpy).toHaveBeenCalledWith({ratings: expectedRatings})

      const saveButton = getByText('Save Mastery Scale').closest('button')
      expect(saveButton.disabled).toEqual(true)
    })

    it('masteryIndex remains at the correct index when sorting and deleting in a single update', () => {
      const {getByText, getAllByText, getByDisplayValue} = render(
        <ProficiencyTable {...customProficiencyProps} update={updateSpy} />
      )

      const pointsInput = getByDisplayValue('3')
      const masteryButton = getAllByText(/Mastery.*for mastery level/)[2].closest('label')

      fireEvent.change(pointsInput, {target: {value: '20'}})
      fireEvent.click(masteryButton)
      fireEvent.click(getAllByText(/Delete mastery level/)[0].closest('button'))
      fireEvent.click(getByText(/Confirm/).closest('button'))
      fireEvent.click(getByText('Save Mastery Scale'))
      fireEvent.click(getByText('Save'))

      const updatedRating1 = {...defaultRating3, mastery: true, points: 20}
      const updatedRating2 = {...defaultRating2, mastery: false}
      const expectedRatings = [updatedRating1, updatedRating2]
      expect(updateSpy).toHaveBeenLastCalledWith({ratings: expectedRatings})

      const saveButton = getByText('Save Mastery Scale').closest('button')
      expect(saveButton.disabled).toEqual(true)
    })
  })

  it('renders one rating that is not deletable', () => {
    const props = {
      ...defaultProps(),
      proficiency: {
        proficiencyRatingsConnection: {
          nodes: [
            {
              description: 'Uno',
              points: 1,
              color: '0000ff',
              mastery: true,
            },
          ],
        },
      },
    }
    const {getAllByText} = render(<ProficiencyTable {...props} />)
    const deleteButtons = getAllByText(/Delete mastery level/).map(el => el.closest('button'))
    expect(deleteButtons.length).toEqual(1)
    expect(deleteButtons[0].disabled).toEqual(true)
  })

  describe('can not manage', () => {
    const props = {
      ...defaultProps(),
      canManage: false,
      proficiency: {
        proficiencyRatingsConnection: {
          nodes: [
            {
              description: 'Great',
              points: 10,
              color: '0000ff',
              mastery: true,
            },
            {
              description: 'Poor',
              points: 0,
              color: 'ff0000',
              mastery: false,
            },
          ],
        },
      },
    }

    it('does not render Save button', () => {
      const {queryByText} = render(<ProficiencyTable {...props} />)
      expect(queryByText('Save Mastery Scale')).not.toBeInTheDocument()
    })

    it('does not render Add button', () => {
      const {queryByText} = render(<ProficiencyTable {...props} />)
      expect(queryByText('Add Mastery Scale')).not.toBeInTheDocument()
    })
  })
})

describe('confirmation modal', () => {
  it('renders correct text for the Account context', () => {
    const {getByDisplayValue, getByText} = render(<ProficiencyTable {...defaultProps()} />)
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '1000'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(getByText(/Confirm Mastery Scale/)).not.toBeNull()
    expect(getByText(/all account and course level rubrics/)).not.toBeNull()
  })

  it('renders correct text for the Course context', () => {
    const {getByDisplayValue, getByText} = render(
      <ProficiencyTable {...defaultProps()} contextType="Course" />
    )
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '1000'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(getByText(/Confirm Mastery Scale/)).not.toBeNull()
    expect(getByText(/all rubrics aligned to outcomes within this course/)).not.toBeNull()
  })
})
