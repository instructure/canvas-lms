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

import React from 'react'
import {renderHook} from '@testing-library/react-hooks/dom'
import useInboxSettingsValidate from '../useInboxSettingsValidate'

describe('useInboxSettingsValidate', () => {
  let focusMock: () => void

  const defaultProps = (props = {}) => ({
    firstDateError: false,
    lastDateError: false,
    subjectError: false,
    messageError: false,
    signatureError: false,
    ...props,
  })

  beforeEach(() => {
    focusMock = jest.fn()
  })

  afterEach(() => {
    jest.resetAllMocks()
  })

  it('creates custom hook with proper exports', () => {
    const {result} = renderHook(() => useInboxSettingsValidate())
    expect(typeof result.current.fieldWithError).toBe('object')
    expect(typeof result.current.validateForm).toBe('function')
    expect(typeof result.current.focusOnError).toBe('function')
    expect(typeof result.current.setFirstDateRef).toBe('function')
    expect(typeof result.current.setLastDateRef).toBe('function')
    expect(typeof result.current.setSubjectRef).toBe('function')
    expect(typeof result.current.setMessageRef).toBe('function')
    expect(typeof result.current.setSignatureRef).toBe('function')
  })

  it('returns true for validateForm if no errors', () => {
    const {result} = renderHook(() => useInboxSettingsValidate())
    const validateResult = result.current.validateForm({...defaultProps()})
    expect(validateResult).toBe(true)
  })

  it('validates first date for errors', () => {
    const {result} = renderHook(() => useInboxSettingsValidate())
    const validateFirstDate = result.current.validateForm({
      ...defaultProps({firstDateError: true}),
    })
    expect(validateFirstDate).toBe(false)
    expect(result.current.fieldWithError).toBe('first_date')
  })

  it('validates last date for errors', () => {
    const {result} = renderHook(() => useInboxSettingsValidate())
    const validateLastDate = result.current.validateForm({
      ...defaultProps({lastDateError: true}),
    })
    expect(validateLastDate).toBe(false)
    expect(result.current.fieldWithError).toBe('last_date')
  })

  it('validates subject for errors', () => {
    const {result} = renderHook(() => useInboxSettingsValidate())
    const validateSubject = result.current.validateForm({
      ...defaultProps({subjectError: true}),
    })
    expect(validateSubject).toBe(false)
    expect(result.current.fieldWithError).toBe('subject')
  })

  it('validates message for errors', () => {
    const {result} = renderHook(() => useInboxSettingsValidate())
    const validateMessage = result.current.validateForm({
      ...defaultProps({messageError: true}),
    })
    expect(validateMessage).toBe(false)
    expect(result.current.fieldWithError).toBe('message')
  })

  it('validates signature for errors', () => {
    const {result} = renderHook(() => useInboxSettingsValidate())
    const validateSignature = result.current.validateForm({
      ...defaultProps({signatureError: true}),
    })
    expect(validateSignature).toBe(false)
    expect(result.current.fieldWithError).toBe('signature')
  })

  it('puts focus on the element with error when focusOnError called', () => {
    const {result, rerender} = renderHook(() => useInboxSettingsValidate())
    const validateSignature = result.current.validateForm({
      ...defaultProps({signatureError: true}),
    })
    const el: HTMLTextAreaElement = document.createElement('textarea')
    el.focus = focusMock
    result.current.setSignatureRef(el)
    expect(validateSignature).toBe(false)
    expect(result.current.fieldWithError).toBe('signature')
    result.current.focusOnError()
    rerender()
    expect(result.current.fieldWithError).toBe(null)
    expect(focusMock).toHaveBeenCalled()
  })
})
