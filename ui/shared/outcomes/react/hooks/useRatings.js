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

import {useMemo, useState, useCallback} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {v1 as uuid} from 'uuid'
import useBoolean from './useBoolean'

const I18n = useI18nScope('useRatings')

const floatRegex = /^[+-]?\d+(\.\d+)?$/

export const createRating = (
  description,
  points,
  mastery,
  focusField = null,
  color = '#ffffff'
) => ({
  description,
  points,
  focusField,
  color,
  mastery,
  key: uuid(),
})

export const defaultRatings = [
  createRating(I18n.t('Exceeds Mastery'), 4, false),
  createRating(I18n.t('Mastery'), 3, true),
  createRating(I18n.t('Near Mastery'), 2, false),
  createRating(I18n.t('Below Mastery'), 1, false),
  createRating(I18n.t('No Evidence'), 0, false),
]

export const defaultMasteryPoints = 3

export const prepareRatings = ratings =>
  (ratings || []).map(({description, points, focusField}) =>
    createRating(description, points, focusField)
  )

const invalidDescription = description => (description?.trim() || '').length === 0

const useRatings = ({initialRatings, initialMasteryPoints}) => {
  const [ratings, setRatings] = useState(() => prepareRatings(initialRatings))
  const [masteryPoints, setMasteryPoints] = useState(initialMasteryPoints)
  const [hasChanged, setHasChanged] = useBoolean(false)

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
        points,
        pointsError,
        descriptionError,
      }
    })
  }, [ratings])

  const masteryPointsWithValidations = useMemo(() => {
    let error = null
    const masteryPointsFloat = masteryPoints ? parseFloat(masteryPoints) : null

    if (ratings.length > 0) {
      const sortedRatings = [...ratings].sort((a, b) => parseFloat(a.points) - parseFloat(b.points))
      const minRatingPoints = parseFloat(sortedRatings[0].points)
      const maxRatingPoints = parseFloat(sortedRatings[sortedRatings.length - 1].points)

      if ([null, undefined, ''].includes(masteryPoints)) {
        error = I18n.t('Missing required points')
      } else if (!floatRegex.test(masteryPoints)) {
        error = I18n.t('Invalid points')
      } else if (masteryPointsFloat < 0) {
        error = I18n.t('Negative points')
      } else if (masteryPointsFloat > maxRatingPoints) {
        error = I18n.t('Above max rating')
      } else if (masteryPointsFloat < minRatingPoints) {
        error = I18n.t('Below min rating')
      }
    }

    return {
      value: masteryPointsFloat,
      error,
    }
  }, [ratings, masteryPoints])

  const hasError = useMemo(() => {
    return (
      ratingsWithValidations.some(r => r.pointsError || r.descriptionError) ||
      masteryPointsWithValidations.error
    )
  }, [ratingsWithValidations, masteryPointsWithValidations])

  const ratingsError = useMemo(
    () => ratingsWithValidations.some(r => r.pointsError || r.descriptionError),
    [ratingsWithValidations]
  )

  const masteryPointsError = useMemo(
    () => Boolean(masteryPointsWithValidations.error),
    [masteryPointsWithValidations]
  )

  const changeRatings = useCallback(
    value => {
      if (!hasChanged) setHasChanged()
      setRatings(value)
    },
    [hasChanged, setHasChanged]
  )

  const changeMasteryPoints = useCallback(
    value => {
      if (!hasChanged) setHasChanged()
      setMasteryPoints(value)
    },
    [hasChanged, setHasChanged]
  )

  const prepareFocusClear = ratingsArr => ratingsArr.map(r => ({...r, focusField: null}))

  const clearRatingsFocus = useCallback(() => setRatings(prepareFocusClear(ratings)), [ratings])

  const focusOnRatingsError = useCallback(() => {
    const updatedRatings = prepareFocusClear(ratings)

    for (let i = 0; i < updatedRatings.length; i++) {
      if (ratingsWithValidations[i].descriptionError) {
        updatedRatings[i].focusField = 'description'
      } else if (ratingsWithValidations[i].pointsError) {
        updatedRatings[i].focusField = 'points'
      }
      if (updatedRatings[i].focusField) break
    }

    setRatings(updatedRatings)
  }, [ratings, ratingsWithValidations])

  return {
    ratings: ratingsWithValidations,
    masteryPoints: masteryPointsWithValidations,
    setRatings: changeRatings,
    setMasteryPoints: changeMasteryPoints,
    hasError,
    hasChanged,
    ratingsError,
    masteryPointsError,
    clearRatingsFocus,
    focusOnRatingsError,
  }
}

export default useRatings
