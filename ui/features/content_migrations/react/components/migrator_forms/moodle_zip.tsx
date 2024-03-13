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

import React, {useCallback, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import {Text} from '@instructure/ui-text'
import CommonMigratorControls from './common_migrator_controls'
import type {onSubmitMigrationFormCallback} from '../types'
import QuestionBankSelector, {type QuestionBankSettings} from './question_bank_selector'
import MigrationFileInput from './file_input'

const I18n = useI18nScope('content_migrations_redesign')

type MoodleZipImporterProps = {
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
  fileUploadProgress: number | null
}

const MoodleZipImporter = ({onSubmit, onCancel, fileUploadProgress}: MoodleZipImporterProps) => {
  const [file, setFile] = useState<File | null>(null)
  const [fileError, setFileError] = useState<boolean>(false)
  const [questionBankSettings, setQuestionBankSettings] = useState<QuestionBankSettings | null>()
  const [questionBankError, setQuestionBankError] = useState<boolean>(false)

  const handleSubmit = useCallback(
    formData => {
      if (!file) {
        setFileError(true)
      }
      if (questionBankSettings) {
        setQuestionBankError(questionBankSettings.question_bank_name === '')
        if (questionBankSettings.question_bank_name === '') {
          return
        }
        formData.settings = {...formData.settings, ...questionBankSettings}
      }
      if (file) {
        setFileError(false)
        formData.pre_attachment = {
          name: file.name,
          size: file.size,
          no_redirect: true,
        }
        onSubmit(formData, file)
      }
    },
    [onSubmit, file, questionBankSettings]
  )

  return (
    <>
      <MigrationFileInput fileUploadProgress={fileUploadProgress} onChange={setFile} />
      {fileError && (
        <p>
          <Text color="danger">{I18n.t('You must select a file to import content from')}</Text>
        </p>
      )}
      <QuestionBankSelector
        onChange={setQuestionBankSettings}
        questionBankError={questionBankError}
      />
      <CommonMigratorControls
        fileUploadProgress={fileUploadProgress}
        canAdjustDates={true}
        onSubmit={handleSubmit}
        onCancel={onCancel}
      />
    </>
  )
}

export default MoodleZipImporter
