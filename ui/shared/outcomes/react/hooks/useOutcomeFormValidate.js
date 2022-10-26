/*
 * Copyright (C) 2022 - present Instructure, Inc.
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
import useInputFocus from './useInputFocus'
import useCanvasContext from './useCanvasContext'

const useOutcomeFormValidate = ({focusOnRatingsError, clearRatingsFocus}) => {
  const {friendlyDescriptionFF, accountLevelMasteryScalesFF} = useCanvasContext()
  const [focusOnErrorField, setFocusOnErrorField] = useState(false)
  const [fieldWithError, setFieldWithError] = useState(null)
  const fields = ['title', 'display_name']
  if (friendlyDescriptionFF) {
    fields.push('friendly_description')
  }
  if (!accountLevelMasteryScalesFF) {
    fields.push('mastery_points', 'individual_calculation_method')
  }
  const {inputElRefs, setInputElRef} = useInputFocus(fields)
  const setTitleRef = el => setInputElRef(el, 'title')
  const setDisplayNameRef = el => setInputElRef(el, 'display_name')
  const setFriendlyDescriptionRef = el => setInputElRef(el, 'friendly_description')
  const setMasteryPointsRef = el => setInputElRef(el, 'mastery_points')
  const setCalcIntRef = el => setInputElRef(el, 'individual_calculation_method')

  const validateForm = ({
    proficiencyCalculationError,
    masteryPointsError,
    ratingsError,
    friendlyDescriptionError,
    displayNameError,
    titleError,
  }) => {
    let errField = null
    typeof clearRatingsFocus === 'function' && clearRatingsFocus()

    // validate form fields in reverse order to focus on first field with error
    if (!accountLevelMasteryScalesFF) {
      if (proficiencyCalculationError) errField = 'individual_calculation_method'
      if (masteryPointsError) errField = 'mastery_points'
      if (ratingsError) errField = 'individual_ratings'
    }
    if (friendlyDescriptionFF && friendlyDescriptionError) errField = 'friendly_description'
    if (displayNameError) errField = 'display_name'
    if (titleError) errField = 'title'

    setFieldWithError(errField)

    return errField === null
  }

  useEffect(() => {
    if (fieldWithError) {
      if (fieldWithError === 'individual_ratings') {
        typeof focusOnRatingsError === 'function' && focusOnRatingsError()
      } else {
        inputElRefs.get(fieldWithError)?.current?.focus()
      }
      setFieldWithError(null)
    }
  }, [focusOnErrorField]) // eslint-disable-line react-hooks/exhaustive-deps

  const focusOnError = () => setFocusOnErrorField(!focusOnErrorField)

  return {
    fieldWithError,
    validateForm,
    focusOnError,
    setTitleRef,
    setDisplayNameRef,
    setFriendlyDescriptionRef,
    setMasteryPointsRef,
    setCalcIntRef,
  }
}

export default useOutcomeFormValidate
