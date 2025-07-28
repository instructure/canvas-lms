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
  file: File | null,
  fileInputRef: React.RefObject<HTMLInputElement | null> | null = null,
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
    fileInputRef?.current?.focus()
    setFileError(true)
  }
}

const isFormInvalid = (formData: any, setFileError: Dispatch<SetStateAction<boolean>>): boolean => {
  if (!formData) {
    setFileError(true)
    return true
  }

  return false
}

const useSubmitHandler = (
  onSubmit: onSubmitMigrationFormCallback,
  fileInputRef: React.RefObject<HTMLInputElement | null> | null = null,
) => {
  const [file, setFile] = useState<File | null>(null)
  const [fileError, setFileError] = useState<boolean>(false)

  const handleSubmit = useCallback(
    // @ts-expect-error
    formData => {
      if (isFormInvalid(formData, setFileError)) {
        return
      }

      submit(formData, setFileError, onSubmit, file, fileInputRef)
    },
    [onSubmit, file, fileInputRef],
  )

  return {
    file,
    setFile,
    fileError,
    handleSubmit,
  }
}

const useSubmitHandlerWithQuestionBank = (
  onSubmit: onSubmitMigrationFormCallback,
  fileInputRef: React.RefObject<HTMLInputElement | null> | null = null,
) => {
  const [file, setFile] = useState<File | null>(null)
  const [fileError, setFileError] = useState<boolean>(false)
  const [questionBankSettings, setQuestionBankSettings] = useState<QuestionBankSettings | null>(
    null,
  )

  const handleSubmit = useCallback(
    // @ts-expect-error
    formData => {
      if (isFormInvalid(formData, setFileError)) {
        return
      }

      if (questionBankSettings) {
        formData.settings = {...formData.settings, ...(questionBankSettings || {})}
      }

      submit(formData, setFileError, onSubmit, file, fileInputRef)
    },
    [onSubmit, file, questionBankSettings, fileInputRef],
  )

  return {
    file,
    setFile,
    fileError,
    questionBankSettings,
    setQuestionBankSettings,
    handleSubmit,
  }
}

export {useSubmitHandlerWithQuestionBank, useSubmitHandler}
