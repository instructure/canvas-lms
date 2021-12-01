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
import {render as realRender, fireEvent} from '@testing-library/react'
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

  const defaultProps = (props = {}) => ({
    onChangeRatings: onChangeRatingsMock,
    canManage: true,
    ratings: [
      createRating('Exceeds Mastery', 4, '127A1B'),
      createRating('Mastery', 3, '00AC18', true)
    ],
    ...props
  })

  beforeEach(() => {
    onChangeRatingsMock = jest.fn()
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

    it('call onChangeRatings with correct mastery when change mastery', () => {
      const {getByLabelText} = render(<Ratings {...defaultProps()} />)
      const mastery = getByLabelText('Mastery false for mastery level 1').closest('input')
      fireEvent.click(mastery)
      expect(onChangeRatingsMock).toHaveBeenCalled()
      const newRatings = onChangeRatingsMock.mock.calls[0][0](defaultProps().ratings)
      // assert set false to previous mastery too
      expect(newRatings.map(r => r.mastery)).toStrictEqual([true, false])
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
      fireEvent.click(getByText('Confirm'))
      expect(onChangeRatingsMock).toHaveBeenCalled()
      const newRatings = onChangeRatingsMock.mock.calls[0][0](defaultProps().ratings)
      expect(newRatings.length).toEqual(1)
      expect(newRatings[0].description).toEqual('Mastery')
    })

    it('calls onChangeRatings when delete a mastery rating with new mastery', () => {
      const {getByText} = render(<Ratings {...defaultProps()} />)
      fireEvent.click(getByText('Delete mastery level 2'))
      fireEvent.click(getByText('Confirm'))
      expect(onChangeRatingsMock).toHaveBeenCalled()
      const newRatings = onChangeRatingsMock.mock.calls[0][0](defaultProps().ratings)
      expect(newRatings.length).toEqual(1)
      expect(newRatings[0].description).toEqual('Exceeds Mastery')
      expect(newRatings[0].mastery).toBeTruthy()
    })
  })

  describe('Permissions', () => {
    describe('when canManage is false', () => {
      it('does not show Add Mastery Level button', () => {
        const {queryByText} = render(<Ratings {...defaultProps({canManage: false})} />)
        expect(queryByText(/Add Mastery Level/)).not.toBeInTheDocument()
      })
    })

    describe('when canManage is true', () => {
      it('show Add Mastery Level button', () => {
        const {queryByText} = render(<Ratings {...defaultProps()} />)
        expect(queryByText(/Add Mastery Level/)).toBeInTheDocument()
      })
    })
  })
})
