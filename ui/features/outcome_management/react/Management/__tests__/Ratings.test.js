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
import {render as realRender, fireEvent, within} from '@testing-library/react'
import Ratings from '../Ratings'
import {createRating} from '@canvas/outcomes/react/hooks/useRatings'
import OutcomesContext from '@canvas/outcomes/react/contexts/OutcomesContext'

const render = (children, {isMobileView = false} = {}) => {
  return realRender(
    <OutcomesContext.Provider value={{env: {isMobileView}}}>{children}</OutcomesContext.Provider>
  )
}

describe('Ratings', () => {
  let onChangeRatingsMock
  let onChangeMasteryPointsMock

  const defaultProps = (props = {}) => ({
    onChangeRatings: onChangeRatingsMock,
    onChangeMasteryPoints: onChangeMasteryPointsMock,
    canManage: true,
    ratings: [createRating('Exceeds Mastery', 4), createRating('Mastery', 3)],
    masteryPoints: {
      value: 3,
      error: null
    },
    ...props
  })

  beforeEach(() => {
    onChangeRatingsMock = jest.fn()
    onChangeMasteryPointsMock = jest.fn()
  })

  afterEach(() => {
    jest.clearAllMocks()
  })

  describe('callbacks', () => {
    it('call onChangeRatings when change any field of a rating', () => {
      const {getByLabelText} = render(<Ratings {...defaultProps()} />)
      const description = getByLabelText('Change description for mastery level 2')
      fireEvent.change(description, {target: {value: 'New value for description'}})
      expect(onChangeRatingsMock).toHaveBeenCalled()
      const newRatings = onChangeRatingsMock.mock.calls[0][0](defaultProps().ratings)
      expect(newRatings[1].description).toEqual('New value for description')
    })

    it('calls onChangeRatings when Add Mastery Level is clicked', () => {
      const {getByText} = render(<Ratings {...defaultProps()} />)
      fireEvent.click(getByText('Add Mastery Level'))
      const ratingsLength = onChangeRatingsMock.mock.calls[0][0].length
      const newRating = onChangeRatingsMock.mock.calls[0][0][2]
      expect(ratingsLength).toBe(3)
      expect(newRating.points).toBe(2)
    })

    it('calls onChangeRatings when delete rating without the deleted rating', () => {
      const {getByText} = render(<Ratings {...defaultProps()} />)
      fireEvent.click(getByText('Delete mastery level 1'))
      expect(onChangeRatingsMock).toHaveBeenCalled()
      const newRatings = onChangeRatingsMock.mock.calls[0][0](defaultProps().ratings)
      expect(newRatings.length).toEqual(1)
      expect(newRatings[0].description).toEqual('Mastery')
    })

    it('call onChangeMasteryPoints with new value of points when mastery points are changed', () => {
      const {getByLabelText} = render(<Ratings {...defaultProps()} />)
      fireEvent.change(getByLabelText('Change mastery points').closest('input'), {
        target: {value: '5'}
      })
      expect(onChangeMasteryPointsMock).toHaveBeenCalled()
      expect(onChangeMasteryPointsMock).toHaveBeenCalledWith('5')
    })

    it('displays error message for mastery points if validation error', async () => {
      const {getByDisplayValue} = render(
        <Ratings
          {...defaultProps({
            masteryPoints: {
              value: 11,
              error: 'Invalid points'
            }
          })}
        />
      )
      const masteryPointsInput = getByDisplayValue('11')
      expect(
        within(masteryPointsInput.closest('.points')).getByText('Invalid points')
      ).toBeInTheDocument()
    })
  })

  describe('Permissions', () => {
    describe('when canManage is false', () => {
      it('does not show Add Mastery Level button', () => {
        const {queryByText} = render(<Ratings {...defaultProps({canManage: false})} />)
        expect(queryByText(/Add Mastery Level/)).not.toBeInTheDocument()
      })

      it('shows read only view of mastery points', () => {
        const {getByTestId} = render(<Ratings {...defaultProps({canManage: false})} />)
        expect(getByTestId('read-only-mastery-points')).toBeInTheDocument()
      })
    })

    describe('when canManage is true', () => {
      it('show Add Mastery Level button', () => {
        const {queryByText} = render(<Ratings {...defaultProps()} />)
        expect(queryByText(/Add Mastery Level/)).toBeInTheDocument()
      })

      it('shows mastery points input', () => {
        const {getByTestId} = render(<Ratings {...defaultProps()} />)
        expect(getByTestId('mastery-points-input')).toBeInTheDocument()
      })
    })
  })
})
