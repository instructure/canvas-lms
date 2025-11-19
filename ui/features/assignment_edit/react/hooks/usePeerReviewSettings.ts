/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useState, useEffect} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'

const I18n = createI18nScope('peer_review_settings')

export const MAX_NUM_PEER_REVIEWS = 10

export const usePeerReviewSettings = ({
  peerReviewCount,
  submissionRequired,
}: {
  peerReviewCount: number
  submissionRequired: boolean
}) => {
  const [reviewsRequired, setReviewsRequired] = useState<string>(
    peerReviewCount ? peerReviewCount.toString() : '1',
  )
  const [totalPoints, setTotalPoints] = useState<string>('0')
  const [errorMessageReviewsRequired, setErrorMessageReviewsRequired] = useState<
    string | undefined
  >(undefined)
  const [pointsPerReview, setPointsPerReview] = useState<string>('0')
  const [errorMessagePointsPerReview, setErrorMessagePointsPerReview] = useState<
    string | undefined
  >(undefined)
  const [allowPeerReviewAcrossMultipleSections, setAllowPeerReviewAcrossMultipleSections] =
    useState<boolean>(false)
  const [allowPeerReviewWithinGroups, setAllowPeerReviewWithinGroups] = useState<boolean>(false)
  const [usePassFailGrading, setUsePassFailGrading] = useState<boolean>(false)
  const [anonymousPeerReviews, setAnonymousPeerReviews] = useState<boolean>(false)
  const [submissionsRequiredBeforePeerReviews, setSubmissionsRequiredBeforePeerReviews] =
    useState<boolean>(submissionRequired)

  useEffect(() => {
    setTotalPoints(calculateTotalPoints())
  }, [reviewsRequired, pointsPerReview]) // eslint-disable-line react-hooks/exhaustive-deps

  const handleReviewsRequiredChange = (
    _event: React.ChangeEvent<HTMLInputElement>,
    value: string,
  ) => {
    setReviewsRequired(value)

    // Clear error message if value becomes valid
    const numReviews = stringToNumber(value)
    if (numReviews !== undefined && numReviews >= 0) {
      setErrorMessageReviewsRequired(undefined)
    }
  }

  const validateReviewsRequired = (event: React.FocusEvent<HTMLInputElement>) => {
    let errorMessage

    const inputElement = event.target
    const value = inputElement?.value !== undefined ? inputElement.value : reviewsRequired
    const numReviewsRequired = stringToNumber(value)

    // Check if input is empty but user had entered invalid value (e.g. "-1e")
    if (value === '' && inputElement?.validity && !inputElement.validity.valid) {
      errorMessage = I18n.t('Please enter a valid number.')
    } else if (numReviewsRequired === undefined || value === '' || value === '0') {
      errorMessage = I18n.t('Number of peer reviews is required.')
    } else if (!Number.isInteger(numReviewsRequired)) {
      errorMessage = I18n.t('Number of peer reviews must be a whole number.')
    } else if (numReviewsRequired < 0) {
      errorMessage = I18n.t('Number of peer reviews cannot be negative.')
    } else if (numReviewsRequired > MAX_NUM_PEER_REVIEWS) {
      errorMessage = I18n.t('Number of peer reviews cannot exceed %{max}.', {
        max: MAX_NUM_PEER_REVIEWS,
      })
    }

    setErrorMessageReviewsRequired(errorMessage)
    return errorMessage
  }

  const handlePointsPerReviewChange = (
    _event: React.ChangeEvent<HTMLInputElement>,
    value: string,
  ) => {
    setPointsPerReview(value)

    const numPoints = stringToNumber(value)
    if (numPoints !== undefined && numPoints >= 0) {
      setErrorMessagePointsPerReview(undefined)
    }
  }

  const validatePointsPerReview = (event: React.FocusEvent<HTMLInputElement>) => {
    let errorMessage

    const inputElement = event.target
    const value = inputElement?.value !== undefined ? inputElement.value : pointsPerReview
    const numPoints = stringToNumber(value)

    if (value === '' && inputElement?.validity && !inputElement.validity.valid) {
      errorMessage = I18n.t('Please enter a valid number.')
    } else if (numPoints !== undefined && numPoints < 0) {
      errorMessage = I18n.t('Points per review cannot be negative.')
    }

    setErrorMessagePointsPerReview(errorMessage)
    return errorMessage
  }

  const calculateTotalPoints = () => {
    const numReviewsRequired = stringToNumber(reviewsRequired)
    const numPointsPerReview = stringToNumber(pointsPerReview)
    if (
      !numReviewsRequired ||
      !numPointsPerReview ||
      errorMessageReviewsRequired ||
      errorMessagePointsPerReview
    )
      return '0'

    const total = numReviewsRequired * numPointsPerReview
    return total % 1 === 0 ? total.toString() : total.toFixed(2)
  }

  const handleCrossSectionsCheck = (e: React.ChangeEvent<HTMLInputElement>) => {
    setAllowPeerReviewAcrossMultipleSections(e.target.checked)
  }

  const handleInterGroupCheck = (e: React.ChangeEvent<HTMLInputElement>) => {
    setAllowPeerReviewWithinGroups(e.target.checked)
  }

  const handleUsePassFailCheck = (e: React.ChangeEvent<HTMLInputElement>) => {
    setUsePassFailGrading(e.target.checked)
  }

  const handleAnonymityCheck = (e: React.ChangeEvent<HTMLInputElement>) => {
    setAnonymousPeerReviews(e.target.checked)
  }

  const handleSubmissionRequiredCheck = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSubmissionsRequiredBeforePeerReviews(e.target.checked)
  }

  const resetFields = () => {
    setReviewsRequired('1')
    setPointsPerReview('0')
    setErrorMessageReviewsRequired(undefined)
    setErrorMessagePointsPerReview(undefined)
    setAllowPeerReviewAcrossMultipleSections(false)
    setAllowPeerReviewWithinGroups(false)
    setUsePassFailGrading(false)
    setAnonymousPeerReviews(false)
    setSubmissionsRequiredBeforePeerReviews(false)
  }

  const stringToNumber = (value: string): number | undefined => {
    const num = Number(value)
    return Number.isNaN(num) ? undefined : num
  }

  return {
    reviewsRequired,
    handleReviewsRequiredChange,
    validateReviewsRequired,
    errorMessageReviewsRequired,
    pointsPerReview,
    handlePointsPerReviewChange,
    validatePointsPerReview,
    errorMessagePointsPerReview,
    totalPoints,
    allowPeerReviewAcrossMultipleSections,
    handleCrossSectionsCheck,
    allowPeerReviewWithinGroups,
    handleInterGroupCheck,
    usePassFailGrading,
    handleUsePassFailCheck,
    anonymousPeerReviews,
    handleAnonymityCheck,
    submissionsRequiredBeforePeerReviews,
    handleSubmissionRequiredCheck,
    resetFields,
  }
}
