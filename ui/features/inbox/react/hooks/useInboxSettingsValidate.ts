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

import {useState, useEffect} from 'react'
import useInputFocus from '../../../../shared/outcomes/react/hooks/useInputFocus'

type validateFormParams = {
  firstDateError: boolean
  lastDateError: boolean
  subjectError: boolean
  messageError: boolean
  signatureError: boolean
}

const useInboxSettingsValidate = () => {
  const [triggerFocus, setTriggerFocus] = useState<boolean>(false)
  const [fieldWithError, setFieldWithError] = useState<string | null>(null)
  const fields = ['first_date', 'last_date', 'subject', 'message', 'signature']

  const {inputElRefs, setInputElRef} = useInputFocus(fields)
  const setFirstDateRef = (el: HTMLInputElement | null) => setInputElRef(el, 'first_date')
  const setLastDateRef = (el: HTMLInputElement | null) => setInputElRef(el, 'last_date')
  const setSubjectRef = (el: HTMLInputElement | null) => setInputElRef(el, 'subject')
  const setMessageRef = (el: HTMLTextAreaElement | null) => setInputElRef(el, 'message')
  const setSignatureRef = (el: HTMLTextAreaElement | null) => setInputElRef(el, 'signature')

  const validateForm = ({
    firstDateError,
    lastDateError,
    subjectError,
    messageError,
    signatureError,
  }: validateFormParams) => {
    let errField = null

    // validate fields in proper order to focus on first field with error
    if (firstDateError) errField = 'first_date'
    else if (lastDateError) errField = 'last_date'
    else if (subjectError) errField = 'subject'
    else if (messageError) errField = 'message'
    else if (signatureError) errField = 'signature'

    setFieldWithError(errField)

    return errField === null
  }

  useEffect(() => {
    if (fieldWithError) {
      inputElRefs.get(fieldWithError)?.current?.focus()
      setFieldWithError(null)
    }
  }, [triggerFocus]) // eslint-disable-line react-hooks/exhaustive-deps

  const focusOnError = () => setTriggerFocus(state => !state)

  return {
    fieldWithError,
    validateForm,
    focusOnError,
    setFirstDateRef,
    setLastDateRef,
    setSubjectRef,
    setMessageRef,
    setSignatureRef,
  }
}

export default useInboxSettingsValidate
