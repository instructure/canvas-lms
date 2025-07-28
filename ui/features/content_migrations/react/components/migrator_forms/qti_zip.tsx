/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import React, {useState, useRef} from 'react'
import {CommonMigratorControls, noFileSelectedFormMessage} from '@canvas/content-migrations'
import type {onSubmitMigrationFormCallback} from '../types'
import QuestionBankSelector from './question_bank_selector'
import MigrationFileInput from './file_input'
import {useSubmitHandlerWithQuestionBank} from '../../hooks/form_handler_hooks'
import {ImportLabel} from './import_label'
import {ImportInProgressLabel} from './import_in_progress_label'
import {ImportClearLabel} from './import_clear_label'

type QTIZipImporterProps = {
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
  fileUploadProgress: number | null
  isSubmitting: boolean
}

const QTIZipImporter = ({
  onSubmit,
  onCancel,
  fileUploadProgress,
  isSubmitting,
}: QTIZipImporterProps) => {
  const [isQuestionBankDisabled, setIsQuestionBankDisabled] = useState(false)
  const fileInputRef = useRef<HTMLInputElement | null>(null)

  const {setFile, fileError, questionBankSettings, setQuestionBankSettings, handleSubmit} =
    useSubmitHandlerWithQuestionBank(onSubmit, fileInputRef)

  return (
    <>
      <MigrationFileInput
        fileUploadProgress={fileUploadProgress}
        onChange={setFile}
        isSubmitting={isSubmitting}
        externalFormMessage={fileError ? noFileSelectedFormMessage : undefined}
        isRequired={true}
        inputRef={ref => (fileInputRef.current = ref)}
      />
      <QuestionBankSelector
        onChange={setQuestionBankSettings}
        disable={isSubmitting || isQuestionBankDisabled}
        notCompatible={isQuestionBankDisabled}
        questionBankSettings={questionBankSettings}
      />
      <CommonMigratorControls
        fileUploadProgress={fileUploadProgress}
        isSubmitting={isSubmitting}
        canImportAsNewQuizzes={ENV.NEW_QUIZZES_IMPORT}
        canOverwriteAssessmentContent={true}
        onSubmit={handleSubmit}
        onCancel={onCancel}
        setIsQuestionBankDisabled={setIsQuestionBankDisabled}
        SubmitLabel={ImportLabel}
        SubmittingLabel={ImportInProgressLabel}
        CancelLabel={ImportClearLabel}
      />
    </>
  )
}

export default QTIZipImporter
