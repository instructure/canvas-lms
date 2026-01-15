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
import ProficiencyTable from '../ProficiencyTable'

vi.mock('@canvas/alerts/react/FlashAlert', () => ({
  showFlashAlert: vi.fn(() => vi.fn(() => {})),
}))

const defaultProps = (props = {}) => ({
  update: () => Promise.resolve(),
  contextType: 'Account',
  ...props,
})

describe('custom proficiency', () => {
  afterEach(() => {
    vi.clearAllMocks()
  })

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
    expect(deleteButtons).toHaveLength(2)
    expect(deleteButtons.some(btn => btn.disabled)).toEqual(false)
  })

  describe('ratings are automatically sorted', () => {
    const updateSpy = vi.fn(() => Promise.resolve())
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
        <ProficiencyTable {...customProficiencyProps} update={updateSpy} />,
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
        <ProficiencyTable {...customProficiencyProps} update={updateSpy} />,
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
        <ProficiencyTable {...customProficiencyProps} update={updateSpy} />,
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
        <ProficiencyTable {...customProficiencyProps} update={updateSpy} />,
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
    expect(deleteButtons).toHaveLength(1)
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
  afterEach(() => {
    vi.clearAllMocks()
  })

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
      <ProficiencyTable {...defaultProps()} contextType="Course" />,
    )
    const pointsInput = getByDisplayValue('3')
    fireEvent.change(pointsInput, {target: {value: '1000'}})
    fireEvent.click(getByText('Save Mastery Scale'))
    expect(getByText(/Confirm Mastery Scale/)).not.toBeNull()
    expect(getByText(/all rubrics aligned to outcomes within this course/)).not.toBeNull()
  })
})
