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

import React, {useState, useCallback, type Dispatch, type SetStateAction} from 'react'
import type {onSubmitMigrationFormCallback, QuestionBankSettings} from '../components/types'

const submit = (
  formData: any,
  setFileError: React.Dispatch<React.SetStateAction<boolean>>,
  onSubmit: onSubmitMigrationFormCallback,
  file: File | null
) => {
  if (file) {
    setFileError(false)
    formData.pre_attachment = {
      name: file.name,
      size: file.size,
      no_redirect: true,
    }
    onSubmit(formData, file)
  } else {
    setFileError(true)
  }
}

const isFormInvalid = (
  formData: any,
  setFileError: Dispatch<SetStateAction<boolean>>,
  questionBankSettings?: QuestionBankSettings | null,
  setQuestionBankError?: Dispatch<SetStateAction<boolean>>
): boolean => {
  if (!formData) {
    setFileError(true)
    if (questionBankSettings && setQuestionBankError) {
      setQuestionBankError(true)
    }
    return true
  }

  if (questionBankSettings?.question_bank_name === '') {
    setQuestionBankError && setQuestionBankError(true)
    return true
  }

  return false
}

const useSubmitHandler = (onSubmit: onSubmitMigrationFormCallback) => {
  const [file, setFile] = useState<File | null>(null)
  const [fileError, setFileError] = useState<boolean>(false)

  const handleSubmit = useCallback(
    formData => {
      if (isFormInvalid(formData, setFileError)) {
        return
      }

      submit(formData, setFileError, onSubmit, file)
    },
    [onSubmit, file]
  )

  return {
    file,
    setFile,
    fileError,
    handleSubmit,
  }
}

const useSubmitHandlerWithQuestionBank = (onSubmit: onSubmitMigrationFormCallback) => {
  const [file, setFile] = useState<File | null>(null)
  const [fileError, setFileError] = useState<boolean>(false)
  const [questionBankSettings, setQuestionBankSettings] = useState<QuestionBankSettings | null>(
    null
  )
  const [questionBankError, setQuestionBankError] = useState<boolean>(false)

  const handleSubmit = useCallback(
    formData => {
      if (isFormInvalid(formData, setFileError, questionBankSettings, setQuestionBankError)) {
        return
      }

      if (questionBankSettings) {
        formData.settings = {...formData.settings, ...(questionBankSettings || {})}
      }

      submit(formData, setFileError, onSubmit, file)
    },
    [onSubmit, file, questionBankSettings]
  )

  return {
    file,
    setFile,
    fileError,
    questionBankSettings,
    setQuestionBankSettings,
    questionBankError,
    handleSubmit,
  }
}

export {useSubmitHandlerWithQuestionBank, useSubmitHandler}
