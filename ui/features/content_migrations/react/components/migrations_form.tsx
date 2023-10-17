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

import React, {useEffect, useState} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import {completeUpload} from '@canvas/upload-file'
import {MigratorSpecificForm} from './migrator_specific_form'
import {GeneralMigrationControls} from './general_migration_controls'
import {
  AttachmentProgressResponse,
  ContentMigrationItem,
  ContentMigrationResponse,
  Migrator,
  submitMigrationProps,
} from './types'

const I18n = useI18nScope('content_migrations_redesign')

const {Option: SimpleSelectOption} = SimpleSelect as any

type RequestBody = {
  course_id: string
  migration_type: string
  settings: {
    import_quizzes_next: boolean
    source_course_id?: string
  }
  selective_import: boolean
  date_shift_options: boolean
  pre_attachment?: {
    name: string
    no_redirect: boolean
    size: number
  }
}

export const ContentMigrationsForm = ({
  migrations,
  setMigrations,
}: {
  migrations: ContentMigrationItem[]
  setMigrations: (migrations: ContentMigrationItem[]) => void
}) => {
  const [migrators, setMigrators] = useState<any>([])
  const [chosenMigrator, setChosenMigrator] = useState<string>('empty')
  const [sourceCourse, setSourceCourse] = useState<string>('')
  const [preAttachmentFile, setPreAttachmentFile] = useState<File | null>(null)

  useEffect(() => {
    doFetchApi({
      path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations/migrators`,
    })
      .then((response: {json: Migrator[]}) =>
        setMigrators(
          response.json.sort((a: Migrator, _b: Migrator) => {
            if (a.type === 'course_copy_importer' || a.type === 'canvas_cartridge_importer') {
              return -1
            }
            return 0
          })
        )
      )
      .catch(showFlashError(I18n.t("Couldn't load migrators")))
  }, [])

  const handleFileProgress = (_: AttachmentProgressResponse) => {}
  // console.log(`${(response.loaded / response.total) * 100}%`)

  const handleMigratorChange = (migrator_type: string) => {
    setChosenMigrator(migrator_type)
  }

  const resetForm = () => {
    setChosenMigrator('empty')
    setSourceCourse('')
    setPreAttachmentFile(null)
  }

  const submitMigration = async ({
    selectiveImport,
    importAsNewQuizzes,
    adjustDates,
  }: submitMigrationProps) => {
    const courseId = window.ENV.COURSE_ID
    if (!courseId) {
      return
    }
    const requestBody: RequestBody = {
      course_id: courseId,
      migration_type: chosenMigrator,
      settings: {
        import_quizzes_next: importAsNewQuizzes,
      },
      selective_import: selectiveImport,
      date_shift_options: adjustDates,
    }
    if (chosenMigrator === 'course_copy_importer') {
      requestBody.settings.source_course_id = sourceCourse
    } else if (chosenMigrator === 'canvas_cartridge_importer' && preAttachmentFile) {
      const {size, name} = preAttachmentFile
      requestBody.pre_attachment = {
        size,
        name,
        no_redirect: true,
      }
    }

    const {json} = (await doFetchApi({
      method: 'POST',
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      path: `/api/v1/courses/${courseId}/content_migrations`,
      body: requestBody,
    })) as {json: ContentMigrationResponse} // TODO: remove type assertion once doFetchApi is typed
    if (preAttachmentFile && json.pre_attachment) {
      completeUpload(json.pre_attachment, preAttachmentFile, {
        ignoreResult: true,
        onProgress: handleFileProgress,
      })
    }
    setMigrations([json as ContentMigrationItem].concat(migrations))
    resetForm()
  }

  return (
    <View as="div" padding="0 x-small 0 0" margin="small x-small xx-large 0">
      <Heading level="h2" as="h2" margin="0 0 small">
        {I18n.t('Import Content')}
      </Heading>
      <Text>
        {I18n.t(
          'Use the Import Content tool to migrate course materials from other sources into this course.'
        )}
      </Text>
      <Alert variant="warning">
        {I18n.t(
          'Importing the same course content more than once will overwrite any existing content in the course.'
        )}
      </Alert>
      <hr />
      <View as="div" margin="medium 0" maxWidth="22.5rem">
        {migrators.length > 0 ? (
          <SimpleSelect
            renderLabel={I18n.t('Select Content Type')}
            onChange={(_e: any, {value}: any) => {
              handleMigratorChange(value)
            }}
          >
            <SimpleSelectOption key="empty-option" id="empty" value="empty">
              {I18n.t('Select one')}
            </SimpleSelectOption>
            {migrators.map((o: Migrator) => (
              <SimpleSelectOption key={o.type} id={o.type} value={o.type}>
                {o.name}
              </SimpleSelectOption>
            ))}
          </SimpleSelect>
        ) : (
          I18n.t('Loading options...')
        )}
      </View>
      <MigratorSpecificForm
        migrator={chosenMigrator}
        setSourceCourse={setSourceCourse}
        onSelectPreAttachmentFile={setPreAttachmentFile}
      />
      {chosenMigrator !== 'empty' ? (
        <GeneralMigrationControls submitMigration={submitMigration} />
      ) : null}
    </View>
  )
}

export default ContentMigrationsForm
