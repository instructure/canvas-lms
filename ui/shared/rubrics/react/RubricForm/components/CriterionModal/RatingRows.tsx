/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import {View} from '@instructure/ui-view'
import {DragVerticalLineBreak} from './DragVerticalLineBreak'
import {DragDropContext as DragAndDrop, Droppable, DropResult} from 'react-beautiful-dnd'
import {rangingFrom} from '../../../RubricAssessment'
import {RubricRating} from '../../../types/rubric'
import {AddRatingRow} from './AddRatingRow'
import {RatingRow} from './RatingRow'
import {Button} from '@instructure/ui-buttons'

type RatingRowsProps = {
  ratings: RubricRating[]
  isFullWidth: boolean
  handleDragStart: () => void
  handleDragEnd: (result: DropResult) => void
  handleMoveRating: (index: number, moveValue: number) => void
  addRating: (index: number) => void
  removeRating: (index: number) => void
  updateRating: (index: number, updatedRating: RubricRating) => void
  reorderRatings: () => void
  checkValidation: boolean
  criterionUseRange: boolean
  dragging: boolean
  hidePoints: boolean
  ratingInputRefs: React.MutableRefObject<HTMLInputElement[]>
}
export const RatingRows = ({
  ratings,
  isFullWidth,
  handleDragStart,
  handleDragEnd,
  handleMoveRating,
  addRating,
  removeRating,
  updateRating,
  reorderRatings,
  checkValidation,
  criterionUseRange,
  dragging,
  hidePoints,
  ratingInputRefs,
}: RatingRowsProps) => {
  return (
    <View as="div" position="relative">
      {!hidePoints && isFullWidth && (
        <DragVerticalLineBreak criterionUseRange={criterionUseRange} />
      )}
      <DragAndDrop onDragStart={handleDragStart} onDragEnd={handleDragEnd}>
        <Droppable droppableId="droppable-id">
          {provided => {
            return (
              <div ref={provided.innerRef} {...provided.droppableProps}>
                {ratings.map((rating, index) => {
                  const scale = ratings.length - (index + 1)
                  const rangeStart = rangingFrom(ratings, index)

                  return (
                    <View as="div" key={`rating-row-${rating.id}-${index}`}>
                      {isFullWidth && (
                        <AddRatingRow onClick={() => addRating(index)} isDragging={dragging} />
                      )}
                      <RatingRow
                        handleMoveRating={handleMoveRating}
                        index={index}
                        checkValidation={checkValidation}
                        hidePoints={hidePoints}
                        isFullWidth={isFullWidth}
                        isLastIndex={index === ratings.length - 1}
                        rating={rating}
                        ratingInputRefs={ratingInputRefs}
                        scale={scale}
                        showRemoveButton={ratings.length > 1}
                        criterionUseRange={criterionUseRange}
                        rangeStart={rangeStart}
                        onRemove={() => removeRating(index)}
                        onChange={updatedRating => updateRating(index, updatedRating)}
                        onPointsBlur={reorderRatings}
                      />
                    </View>
                  )
                })}
                {isFullWidth && (
                  <AddRatingRow onClick={() => addRating(ratings.length)} isDragging={dragging} />
                )}
                {!isFullWidth && (
                  <View as="div" margin="large 0">
                    <Button
                      data-testid="add-rating-button"
                      onClick={() => addRating(ratings.length)}
                    >
                      Add Rating
                    </Button>
                  </View>
                )}
                {provided.placeholder}
              </div>
            )
          }}
        </Droppable>
      </DragAndDrop>
    </View>
  )
}
