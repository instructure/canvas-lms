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

import React from 'react'
import {renderHook} from '@testing-library/react-hooks/dom'
import OutcomesContext from '../../contexts/OutcomesContext'
import useOutcomeFormValidate from '../useOutcomeFormValidate'

describe('useOutcomeFormValidate', () => {
  let focusOnRatingsErrorMock
  let clearRatingsFocusMock
  let focusMock

  const defaultProps = (props = {}) => ({
    proficiencyCalculationError: false,
    masteryPointsError: false,
    ratingsError: false,
    friendlyDescriptionError: false,
    displayNameError: false,
    titleError: false,
    ...props,
  })

  beforeEach(() => {
    focusOnRatingsErrorMock = jest.fn()
    clearRatingsFocusMock = jest.fn()
    focusMock = jest.fn()
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  it('creates custom hook with proper exports', () => {
    const {result} = renderHook(() =>
      useOutcomeFormValidate({
        focusOnRatingsError: focusOnRatingsErrorMock,
        clearRatingsFocus: clearRatingsFocusMock,
      })
    )

    expect(typeof result.current.fieldWithError).toBe('object')
    expect(typeof result.current.validateForm).toBe('function')
    expect(typeof result.current.focusOnError).toBe('function')
    expect(typeof result.current.setTitleRef).toBe('function')
    expect(typeof result.current.setDisplayNameRef).toBe('function')
    expect(typeof result.current.setFriendlyDescriptionRef).toBe('function')
    expect(typeof result.current.setMasteryPointsRef).toBe('function')
    expect(typeof result.current.setCalcIntRef).toBe('function')
  })

  it('clears focus before running validations', () => {
    const {result} = renderHook(() =>
      useOutcomeFormValidate({
        focusOnRatingsError: focusOnRatingsErrorMock,
        clearRatingsFocus: clearRatingsFocusMock,
      })
    )

    result.current.validateForm({...defaultProps()})
    expect(clearRatingsFocusMock).toHaveBeenCalled()
  })

  it('returns true for validateForm if no errors', () => {
    const {result} = renderHook(() =>
      useOutcomeFormValidate({
        focusOnRatingsError: focusOnRatingsErrorMock,
        clearRatingsFocus: clearRatingsFocusMock,
      })
    )

    const validateResult = result.current.validateForm({...defaultProps()})
    expect(validateResult).toBe(true)
  })

  it('validates title and display name for errors', () => {
    const {result} = renderHook(() =>
      useOutcomeFormValidate({
        focusOnRatingsError: focusOnRatingsErrorMock,
        clearRatingsFocus: clearRatingsFocusMock,
      })
    )

    const validateDisplayName = result.current.validateForm({
      ...defaultProps({displayNameError: true}),
    })
    expect(validateDisplayName).toBe(false)
    expect(result.current.fieldWithError).toBe('display_name')

    const validateTitle = result.current.validateForm({
      ...defaultProps({titleError: true}),
    })
    expect(validateTitle).toBe(false)
    expect(result.current.fieldWithError).toBe('title')
  })

  it('validates friendly description for errors if friendly description FF is enabled', () => {
    const wrapper = ({children}) => (
      <OutcomesContext.Provider
        value={{
          env: {
            friendlyDescriptionFF: true,
          },
        }}
      >
        {children}
      </OutcomesContext.Provider>
    )
    const {result} = renderHook(
      () =>
        useOutcomeFormValidate({
          focusOnRatingsError: focusOnRatingsErrorMock,
          clearRatingsFocus: clearRatingsFocusMock,
        }),
      {wrapper}
    )

    const validateFriendlyDescriptionError = result.current.validateForm({
      ...defaultProps({friendlyDescriptionError: true}),
    })
    expect(validateFriendlyDescriptionError).toBe(false)
    expect(result.current.fieldWithError).toBe('friendly_description')
  })

  it('validates ratings, mastery points and calculation method for errors if account level mastery scales FF is disabled', () => {
    const wrapper = ({children}) => (
      <OutcomesContext.Provider
        value={{
          env: {
            accountLevelMasteryScalesFF: false,
          },
        }}
      >
        {children}
      </OutcomesContext.Provider>
    )

    const {result} = renderHook(
      () =>
        useOutcomeFormValidate({
          focusOnRatingsError: focusOnRatingsErrorMock,
          clearRatingsFocus: clearRatingsFocusMock,
        }),
      {wrapper}
    )

    const validateRatingsError = result.current.validateForm({
      ...defaultProps({ratingsError: true}),
    })
    expect(validateRatingsError).toBe(false)
    expect(result.current.fieldWithError).toBe('individual_ratings')

    const validateMasteryPointsError = result.current.validateForm({
      ...defaultProps({masteryPointsError: true}),
    })
    expect(validateMasteryPointsError).toBe(false)
    expect(result.current.fieldWithError).toBe('mastery_points')

    const validateCalculationMethodError = result.current.validateForm({
      ...defaultProps({proficiencyCalculationError: true}),
    })
    expect(validateCalculationMethodError).toBe(false)
    expect(result.current.fieldWithError).toBe('individual_calculation_method')
  })

  it('calls focusOnRatingsError if ratings have errors and focusOnError called', () => {
    const wrapper = ({children}) => (
      <OutcomesContext.Provider
        value={{
          env: {
            accountLevelMasteryScalesFF: false,
          },
        }}
      >
        {children}
      </OutcomesContext.Provider>
    )
    const {result, rerender} = renderHook(
      () =>
        useOutcomeFormValidate({
          focusOnRatingsError: focusOnRatingsErrorMock,
          clearRatingsFocus: clearRatingsFocusMock,
        }),
      {wrapper}
    )

    const validateRatingsError = result.current.validateForm({
      ...defaultProps({ratingsError: true}),
    })
    expect(validateRatingsError).toBe(false)
    expect(result.current.fieldWithError).toBe('individual_ratings')
    result.current.focusOnError()
    rerender()
    expect(focusOnRatingsErrorMock).toHaveBeenCalled()
    expect(result.current.fieldWithError).toBe(null)
  })

  it('calls focus fn on the element with error if errors not in ratings and focusOnError called', () => {
    const wrapper = ({children}) => (
      <OutcomesContext.Provider value={{env: {}}}>{children}</OutcomesContext.Provider>
    )
    const {result, rerender} = renderHook(
      () =>
        useOutcomeFormValidate({
          focusOnRatingsError: focusOnRatingsErrorMock,
          clearRatingsFocus: clearRatingsFocusMock,
        }),
      {wrapper}
    )

    const validateTitleError = result.current.validateForm({
      ...defaultProps({titleError: true}),
    })
    const el = {focus: focusMock}
    result.current.setTitleRef(el)
    expect(validateTitleError).toBe(false)
    expect(result.current.fieldWithError).toBe('title')
    result.current.focusOnError()
    rerender()
    expect(focusOnRatingsErrorMock).not.toHaveBeenCalled()
    expect(result.current.fieldWithError).toBe(null)
    expect(focusMock).toHaveBeenCalled()
  })
})
