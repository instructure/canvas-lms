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
import $ from 'jquery'
import {render} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import Ratings, {Rating} from '../Ratings'
import fakeENV from '@canvas/test-utils/fakeENV'

// This is needed for $.screenReaderFlashMessageExclusive to work.
import '@canvas/rails-flash-notifications'

describe('The Ratings component', () => {
  const defaultProps = {
    assessing: false,
    footer: null,
    tiers: [
      {id: '1', description: 'Superb', points: 10},
      {id: '2', description: 'Meh', long_description: 'More Verbosity', points: 5},
      {id: '3', description: 'Subpar', points: 1},
    ],
    defaultMasteryThreshold: 10,
    selectedRatingId: '2',
    points: 5,
    pointsPossible: 10,
    isSummary: false,
    useRange: false,
  }

  afterEach(() => {
    jest.restoreAllMocks()
  })

  it('renders the root component as expected', () => {
    const {container} = render(<Ratings {...defaultProps} />)
    const ratings = container.querySelectorAll('.rating-tier')

    expect(ratings).toHaveLength(3)
    expect(container).toHaveTextContent('Superb')
    expect(container).toHaveTextContent('Meh')
    expect(container).toHaveTextContent('Subpar')

    // Assert position of text content - should appear in order from left to right
    const firstRating = ratings[0]
    const secondRating = ratings[1]
    const thirdRating = ratings[2]

    expect(firstRating).toHaveTextContent('Superb')
    expect(firstRating).toHaveTextContent('10 pts')
    expect(secondRating).toHaveTextContent('Meh')
    expect(secondRating).toHaveTextContent('5 pts')
    expect(thirdRating).toHaveTextContent('Subpar')
    expect(thirdRating).toHaveTextContent('1 pts')

    // Verify ratings are in the correct order in the DOM
    // Simply verify that the ratings array is in the expected order
    // since querySelectorAll returns elements in document order
    expect(ratings[0]).toHaveTextContent('Superb')
    expect(ratings[1]).toHaveTextContent('Meh')
    expect(ratings[2]).toHaveTextContent('Subpar')
  })

  it('renders text content in the correct position', () => {
    const {container} = render(<Ratings {...defaultProps} />)
    const ratings = container.querySelectorAll('.rating-tier')

    // Check first rating tier structure
    const firstRating = ratings[0]
    const firstRatingPoints = firstRating.querySelector('.rating-points')
    const firstRatingDescription = firstRating.querySelector('.rating-description')

    expect(firstRatingPoints).toHaveTextContent('10 pts')
    expect(firstRatingDescription).toHaveTextContent('Superb')

    // Verify points come before description in DOM order
    const firstRatingChildren = Array.from(firstRating.children)
    const pointsIndex = firstRatingChildren.indexOf(firstRatingPoints)
    const descriptionIndex = firstRatingChildren.indexOf(firstRatingDescription)
    expect(pointsIndex).toBeLessThan(descriptionIndex)

    // Check second rating tier with long description
    const secondRating = ratings[1]
    const secondRatingDescription = secondRating.querySelector('.rating-description')
    expect(secondRatingDescription).toHaveTextContent('Meh')

    // Check that both main description and long description are present
    expect(secondRating).toHaveTextContent('Meh')
    expect(secondRating).toHaveTextContent('More Verbosity')
  })

  it('renders the Rating sub-components as expected when range rating enabled', () => {
    const {container} = render(<Ratings {...defaultProps} useRange={true} />)
    const ratings = container.querySelectorAll('.rating-tier')

    expect(ratings).toHaveLength(3)
    expect(container).toHaveTextContent('Superb')
    expect(container).toHaveTextContent('Meh')
    expect(container).toHaveTextContent('Subpar')
  })

  it('properly select the first matching rating when two tiers have the same point value and no ID is passed', () => {
    const tiers = [
      {description: 'Superb', points: 10},
      {description: 'Meh', points: 5},
      {description: 'Meh 2, The Sequel', points: 5},
      {description: 'Subpar', points: 1},
    ]
    const {container} = render(<Ratings {...defaultProps} tiers={tiers} selectedRatingId={null} />)
    const ratings = container.querySelectorAll('.rating-tier')

    expect(ratings[0]).not.toHaveClass('selected')
    expect(ratings[1]).toHaveClass('selected')
    expect(ratings[2]).not.toHaveClass('selected')
    expect(ratings[3]).not.toHaveClass('selected')
  })

  it('highlights the right rating when no selectedRatingId present', () => {
    const testCases = [
      {points: 10, useRange: false, expected: [true, false, false]},
      {points: 8, useRange: false, expected: [false, false, false]},
      {points: 8, useRange: true, expected: [true, false, false]},
      {points: 5, useRange: false, expected: [false, true, false]},
      {points: 3, useRange: false, expected: [false, false, false]},
      {points: 3, useRange: true, expected: [false, true, false]},
      {points: 1, useRange: false, expected: [false, false, true]},
      {points: 0, useRange: true, expected: [false, false, true]},
      {points: undefined, useRange: false, expected: [false, false, false]},
    ]

    testCases.forEach(({points, useRange, expected}) => {
      const {container} = render(
        <Ratings {...defaultProps} points={points} useRange={useRange} selectedRatingId={null} />,
      )
      const ratings = container.querySelectorAll('.rating-tier')

      expected.forEach((shouldBeSelected, index) => {
        if (shouldBeSelected) {
          expect(ratings[index]).toHaveClass('selected')
        } else {
          expect(ratings[index]).not.toHaveClass('selected')
        }
      })
    })
  })

  it('calls onPointChange and flashes VO message when a rating is clicked', async () => {
    const user = userEvent.setup()
    const onPointChange = jest.fn()
    const flashMock = jest.spyOn($, 'screenReaderFlashMessage')

    const {container} = render(
      <Ratings {...defaultProps} assessing={true} onPointChange={onPointChange} />,
    )
    const firstRating = container.querySelector('.rating-tier')

    await user.click(firstRating)

    expect(onPointChange).toHaveBeenCalledWith({id: '1', description: 'Superb', points: 10}, false)
    expect(flashMock).toHaveBeenCalledTimes(1)
  })

  it('uses the right default mastery level colors', () => {
    const masteryTests = [
      {points: 10, selectedRatingId: '1', expectedShaders: ['meetsMasteryShader', null, null]},
      {points: 5, selectedRatingId: '2', expectedShaders: [null, 'nearMasteryShader', null]},
      {points: 1, selectedRatingId: '3', expectedShaders: [null, null, 'wellBelowMasteryShader']},
    ]

    masteryTests.forEach(({points, selectedRatingId, expectedShaders}) => {
      const {container} = render(
        <Ratings {...defaultProps} points={points} selectedRatingId={selectedRatingId} />,
      )
      const shaders = container.querySelectorAll('.shader')

      expectedShaders.forEach((expectedClass, index) => {
        if (expectedClass) {
          expect(shaders[index]).toHaveClass(expectedClass)
        }
      })
    })
  })

  it('uses the right custom rating colors', () => {
    const customRatings = [
      {points: 10, color: '09BCD3'},
      {points: 5, color: '65499D'},
      {points: 1, color: 'F8971C'},
    ]

    const colorTests = [
      {points: 10, selectedRatingId: '1', useRange: false, expectedColor: '#09BCD3'},
      {points: 5, selectedRatingId: '2', useRange: false, expectedColor: '#65499D'},
      {points: 1, selectedRatingId: '3', useRange: false, expectedColor: '#F8971C'},
      {points: 0, selectedRatingId: '3', useRange: true, expectedColor: '#F8971C'},
    ]

    colorTests.forEach(({points, selectedRatingId, useRange, expectedColor}) => {
      const {container} = render(
        <Ratings
          {...defaultProps}
          points={points}
          selectedRatingId={selectedRatingId}
          useRange={useRange}
          customRatings={customRatings}
        />,
      )
      const selectedShader = container.querySelector('.selected .shader')
      expect(selectedShader).toHaveStyle(`border-bottom: 0.3em solid ${expectedColor}`)
    })
  })

  describe('custom ratings', () => {
    const customRatings = [
      {points: 100, color: '100100'},
      {points: 60, color: '606060'},
      {points: 10, color: '101010'},
      {points: 1, color: '111111'},
    ]

    it('scales points to custom ratings', () => {
      const scalingTests = [
        {points: 10, selectedRatingId: '1', expectedColor: '#100100'},
        {points: 6, selectedRatingId: '1', expectedColor: '#606060'},
        {points: 5, selectedRatingId: '2', expectedColor: '#101010'},
        {points: 4.4, selectedRatingId: '2', expectedColor: '#101010'},
        {points: 1, selectedRatingId: '3', expectedColor: '#101010'},
        {points: 0.1, selectedRatingId: '3', expectedColor: '#111111'},
        {points: 0, selectedRatingId: '3', expectedColor: '#111111'},
      ]

      scalingTests.forEach(({points, selectedRatingId, expectedColor}) => {
        const {container} = render(
          <Ratings
            {...defaultProps}
            points={points}
            selectedRatingId={selectedRatingId}
            pointsPossible={10}
            customRatings={customRatings}
            useRange={true}
          />,
        )
        const selectedShader = container.querySelector('.selected .shader')
        expect(selectedShader).toHaveStyle(`border-bottom: 0.3em solid ${expectedColor}`)
      })
    })

    it('does not scale points if pointsPossible is 0', () => {
      const {container} = render(
        <Ratings
          {...defaultProps}
          points={10}
          selectedRatingId="1"
          pointsPossible={0}
          customRatings={customRatings}
          useRange={true}
        />,
      )
      const selectedShader = container.querySelector('.selected .shader')
      expect(selectedShader).toHaveStyle('border-bottom: 0.3em solid #101010')
    })
  })

  it('is navigable and clickable when assessing', async () => {
    const user = userEvent.setup()
    const onClick = jest.fn()

    const {container} = render(
      <Rating {...defaultProps.tiers[0]} isSummary={false} assessing={true} onClick={onClick} />,
    )
    const ratingDiv = container.firstChild

    expect(ratingDiv).toHaveAttribute('tabIndex', '0')
    await user.click(ratingDiv)
    expect(onClick).toHaveBeenCalled()
  })

  it('is not navigable or clickable when not assessing', async () => {
    const user = userEvent.setup()
    const onClick = jest.fn()

    const {container} = render(
      <Rating {...defaultProps.tiers[0]} isSummary={false} assessing={false} onClick={onClick} />,
    )
    const ratingDiv = container.firstChild

    expect(ratingDiv).not.toHaveAttribute('tabIndex')
    expect(ratingDiv).not.toHaveAttribute('role')
    await user.click(ratingDiv)
    expect(onClick).not.toHaveBeenCalled()
  })

  it('only renders the single selected Rating with a footer in summary mode', () => {
    const {container, getByText} = render(
      <Ratings {...defaultProps} points={5} isSummary={true} footer={<div>ow my foot</div>} />,
    )
    const ratings = container.querySelectorAll('.rating-tier')

    expect(ratings).toHaveLength(1)
    expect(getByText('Meh')).toBeInTheDocument()
    expect(getByText('ow my foot')).toBeInTheDocument()
  })

  it('renders footer in the correct position within rating', () => {
    const {container} = render(
      <Ratings
        {...defaultProps}
        points={5}
        isSummary={true}
        footer={<div>Custom footer text</div>}
      />,
    )
    const rating = container.querySelector('.rating-tier')
    const description = rating.querySelector('.rating-description')
    const footer = rating.querySelector('.rating-footer')

    expect(footer).toHaveTextContent('Custom footer text')

    // Verify footer comes after description in DOM order
    const ratingChildren = Array.from(rating.children)
    const descriptionIndex = ratingChildren.indexOf(description.parentElement || description)
    const footerIndex = ratingChildren.indexOf(footer)
    expect(descriptionIndex).toBeLessThan(footerIndex)
  })

  it('renders a default rating if none of the ratings are selected', () => {
    const {container} = render(
      <Ratings
        {...defaultProps}
        points={6}
        selectedRatingId={null}
        isSummary={true}
        footer={<div>ow my foot</div>}
      />,
    )
    const ratings = container.querySelectorAll('.rating-tier')

    expect(ratings).toHaveLength(1)
    expect(container).toHaveTextContent('No details')
  })

  it('hides points on the default rating if points are hidden', () => {
    const {queryByTestId} = render(
      <Ratings {...defaultProps} points={6} isSummary={true} footer={<div>ow my foot</div>} />,
    )

    expect(queryByTestId('rating-points')).not.toBeInTheDocument()
  })

  it('renders rating-points when restrictive quantitative data and hidePoints is false', () => {
    const {getByTestId} = render(
      <Rating {...defaultProps.tiers[0]} isSummary={false} assessing={true} hidePoints={false} />,
    )

    expect(getByTestId('rating-points')).toBeInTheDocument()
  })

  it('renders text content in correct order when points are hidden', () => {
    const {container} = render(<Ratings {...defaultProps} hidePoints={true} />)
    const firstRating = container.querySelectorAll('.rating-tier')[0]

    // Verify points are not rendered
    expect(firstRating.querySelector('.rating-points')).toBeNull()

    // Verify description is the first text content
    const firstTextElement = firstRating.querySelector('.rating-description')
    expect(firstTextElement).toHaveTextContent('Superb')

    // Check that description is one of the first children when points are hidden
    const ratingChildren = Array.from(firstRating.children)
    const descriptionIndex = ratingChildren.indexOf(firstTextElement)
    expect(descriptionIndex).toBeLessThanOrEqual(1) // Should be first or second child
  })

  describe('with restrict_quantitative_data', () => {
    beforeEach(() => {
      fakeENV.setup({restrict_quantitative_data: true})
    })

    afterEach(() => {
      fakeENV.teardown()
    })

    it('does not renders rating-points when restrictive quantitative data is true and hidePoints is false', () => {
      const {queryByTestId} = render(
        <Rating {...defaultProps.tiers[0]} isSummary={false} assessing={true} hidePoints={false} />,
      )

      expect(queryByTestId('rating-points')).not.toBeInTheDocument()
    })

    it('does not renders rubric-total when restrictive quantitative data is false and hidePoints if true', () => {
      fakeENV.setup({restrict_quantitative_data: false})

      const {queryByTestId} = render(
        <Rating {...defaultProps.tiers[0]} isSummary={false} assessing={true} hidePoints={true} />,
      )

      expect(queryByTestId('rating-points')).not.toBeInTheDocument()
    })
  })
})
