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

import {useMemo, useState} from 'react'
import I18n from 'i18n!ProficiencyTable'
import uuid from 'uuid/v1'

const floatRegex = /^[+-]?\d+(\.\d+)?$/

export const createRating = (description, points, color, mastery = false) => ({
  description,
  points,
  key: uuid(),
  color,
  mastery
})

export const defaultOutcomesManagementRatings = [
  createRating(I18n.t('Exceeds Mastery'), 4, '127A1B'),
  createRating(I18n.t('Mastery'), 3, '00AC18', true),
  createRating(I18n.t('Near Mastery'), 2, 'FAB901'),
  createRating(I18n.t('Below Mastery'), 1, 'FD5D10'),
  createRating(I18n.t('Well Below Mastery'), 0, 'EE0612')
]

const invalidDescription = description => (description?.trim() || '').length === 0

const useRatings = ({initialRatings}) => {
  const [ratings, setRatings] = useState(initialRatings)

  const ratingsWithValidations = useMemo(() => {
    const allPoints = ratings.map(r => r.points)

    return ratings.map((r, idx) => {
      let pointsError = null
      const points = parseFloat(r.points)
      const pointsIndex = allPoints.findIndex(p =>
        // if float, test parsing float, otherwise, test string
        floatRegex.test(p) ? parseFloat(p) === parseFloat(r.points) : p === r.points
      )

      const descriptionError = invalidDescription(r.description)
        ? I18n.t('Missing required description')
        : null

      if ([null, undefined, ''].includes(r.points)) {
        pointsError = I18n.t('Missing required points')
      } else if (!floatRegex.test(r.points)) {
        pointsError = I18n.t('Invalid points')
      } else if (points < 0) {
        pointsError = I18n.t('Negative points')
      } else if (idx !== pointsIndex) {
        pointsError = I18n.t('Points must be unique')
      }

      return {
        ...r,
        pointsError,
        descriptionError
      }
    })
  }, [ratings])

  const hasError = useMemo(() => {
    return ratingsWithValidations.some(r => r.pointsError || r.descriptionError)
  }, [ratingsWithValidations])

  const hasChanged = useMemo(
    () => JSON.stringify(ratings) !== JSON.stringify(initialRatings),
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [ratings]
  )

  return {
    ratings: ratingsWithValidations,
    setRatings,
    hasError,
    hasChanged
  }
}

export default useRatings
