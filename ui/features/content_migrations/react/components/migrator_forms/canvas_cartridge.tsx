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
import CommonMigratorControls from './common_migrator_controls'
import type {onSubmitMigrationFormCallback} from '../types'
import MigrationFileInput from './file_input'

type CanvasCartridgeImporterProps = {
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
}

const CanvasCartridgeImporter = ({onSubmit, onCancel}: CanvasCartridgeImporterProps) => {
  const [file, setFile] = useState<File | null>(null)

  const handleSubmit: onSubmitMigrationFormCallback = useCallback(
    formData => {
      if (file) {
        formData.pre_attachment = {
          name: file.name,
          size: file.size,
          no_redirect: true,
        }
        onSubmit(formData, file)
      }
    },
    [file, onSubmit]
  )

  return (
    <>
      <MigrationFileInput onChange={setFile} />
      <CommonMigratorControls
        canSelectContent={true}
        canImportAsNewQuizzes={ENV.NEW_QUIZZES_MIGRATION}
        canAdjustDates={true}
        onSubmit={handleSubmit}
        onCancel={onCancel}
      />
    </>
  )
}

export default CanvasCartridgeImporter
