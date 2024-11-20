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

import React from 'react'

import {CommonMigratorControls, noFileSelectedFormMessage} from '@canvas/content-migrations'
import type {onSubmitMigrationFormCallback} from '../types'
import QuestionBankSelector from './question_bank_selector'
import MigrationFileInput from './file_input'
import {parseDateToISOString} from '../utils'
import {useSubmitHandlerWithQuestionBank} from '../../hooks/form_handler_hooks'
import {ImportLabel} from './import_label'

type MoodleZipImporterProps = {
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
  fileUploadProgress: number | null
  isSubmitting: boolean
}

const MoodleZipImporter = ({
  onSubmit,
  onCancel,
  fileUploadProgress,
  isSubmitting,
}: MoodleZipImporterProps) => {
  const {
    setFile,
    fileError,
    questionBankSettings,
    setQuestionBankSettings,
    questionBankError,
    handleSubmit,
  } = useSubmitHandlerWithQuestionBank(onSubmit)

  return (
    <>
      <MigrationFileInput
        fileUploadProgress={fileUploadProgress}
        onChange={setFile}
        isSubmitting={isSubmitting}
        externalFormMessage={fileError ? noFileSelectedFormMessage : undefined}
        isRequired={true}
      />
      <QuestionBankSelector
        onChange={setQuestionBankSettings}
        questionBankError={questionBankError}
        disable={isSubmitting}
        questionBankSettings={questionBankSettings}
      />
      <CommonMigratorControls
        canSelectContent={true}
        fileUploadProgress={fileUploadProgress}
        isSubmitting={isSubmitting}
        canAdjustDates={true}
        onSubmit={handleSubmit}
        onCancel={onCancel}
        newStartDate={parseDateToISOString(ENV.OLD_START_DATE)}
        newEndDate={parseDateToISOString(ENV.OLD_END_DATE)}
        SubmitLabel={ImportLabel}
      />
    </>
  )
}

export default MoodleZipImporter
