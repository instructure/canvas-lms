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

import React, {useEffect, useState, useCallback} from 'react'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {View} from '@instructure/ui-view'
import {Alert} from '@instructure/ui-alerts'
import {completeUpload} from '@canvas/upload-file'
import CourseCopyImporter from './migrator_forms/course_copy'
import CanvasCartridgeImporter from './migrator_forms/canvas_cartridge'
import LegacyMigratorWrapper from './migrator_forms/legacy_migrator_wrapper'
import {
  AttachmentProgressResponse,
  ContentMigrationItem,
  ContentMigrationResponse,
  Migrator,
  onSubmitMigrationFormCallback,
} from './types'
import CommonMigratorControls from './common_migrator_controls'

const I18n = useI18nScope('content_migrations_redesign')

type RequestBody = {
  course_id: string
  migration_type: string
  date_shift_options: boolean
  selective_import: boolean
  settings: {[key: string]: any}
  pre_attachment?: {
    name: string
    no_redirect: boolean
    size: number
  }
}

type RenderMigratorArgs = {
  migrator: string
  onSubmit: onSubmitMigrationFormCallback
  onCancel: () => void
}

const renderMigrator = ({migrator, onSubmit, onCancel}: RenderMigratorArgs) => {
  if (migrator === 'course_copy_importer') {
    return <CourseCopyImporter onSubmit={onSubmit} onCancel={onCancel} />
  } else if (migrator === 'canvas_cartridge_importer') {
    return <CanvasCartridgeImporter onSubmit={onSubmit} onCancel={onCancel} />
  } else if (['angel_exporter', 'blackboard_exporter', 'd2l_exporter'].includes(migrator)) {
    return <LegacyMigratorWrapper value={migrator} onSubmit={onSubmit} onCancel={onCancel} />
  }
  return <CommonMigratorControls onSubmit={onSubmit} onCancel={onCancel} />
}

export const ContentMigrationsForm = ({
  migrations,
  setMigrations,
}: {
  migrations: ContentMigrationItem[]
  setMigrations: (migrations: ContentMigrationItem[]) => void
}) => {
  const [migrators, setMigrators] = useState<any>([])
  const [chosenMigrator, setChosenMigrator] = useState<string | null>(null)

  const handleFileProgress = (_: AttachmentProgressResponse) => {}
  // console.log(`${(response.loaded / response.total) * 100}%`)

  const onResetForm = useCallback(() => setChosenMigrator(null), [])

  const onSubmitForm: onSubmitMigrationFormCallback = useCallback(
    async (formData, preAttachmentFile) => {
      const courseId = window.ENV.COURSE_ID
      if (!chosenMigrator || !courseId) {
        return
      }
      const requestBody: RequestBody = {
        course_id: courseId,
        migration_type: chosenMigrator,
        ...formData,
      }

      const {json} = (await doFetchApi({
        method: 'POST',
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
      onResetForm()
    },
    [chosenMigrator, migrations, setMigrations, onResetForm]
  )

  useEffect(() => {
    doFetchApi({
      path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations/migrators`,
    })
      .then((response: {json: Migrator[]}) => {
        // TODO: webct_scraper is not supported anymore, this should be removed from backend too.
        const filteredMigrators = response.json.filter((m: Migrator) => m.type !== 'webct_scraper')
        setMigrators(
          filteredMigrators.sort((a: Migrator, _: Migrator) =>
            a.type === 'course_copy_importer' || a.type === 'canvas_cartridge_importer' ? -1 : 0
          )
        )
      })
      .catch(showFlashError(I18n.t("Couldn't load migrators")))
  }, [])

  return (
    <View as="div" margin="small none xx-large none">
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
      <hr role="presentation" aria-hidden="true" />
      <View as="div" margin="medium 0" maxWidth="22.5rem">
        {migrators.length > 0 ? (
          <SimpleSelect
            value={chosenMigrator || 'empty'}
            renderLabel={I18n.t('Select Content Type')}
            onChange={(_e: any, {value}: any) =>
              setChosenMigrator(value !== 'empty' ? value : null)
            }
          >
            <SimpleSelect.Option key="empty-option" id="empty" value="empty">
              {I18n.t('Select one')}
            </SimpleSelect.Option>
            {migrators.map((o: Migrator) => (
              <SimpleSelect.Option key={o.type} id={o.type} value={o.type}>
                {o.name}
              </SimpleSelect.Option>
            ))}
          </SimpleSelect>
        ) : (
          I18n.t('Loading options...')
        )}
      </View>

      {chosenMigrator && (
        <>
          {renderMigrator({
            migrator: chosenMigrator,
            onSubmit: onSubmitForm,
            onCancel: onResetForm,
          })}
          <hr role="presentation" aria-hidden="true" />
        </>
      )}
    </View>
  )
}

export default ContentMigrationsForm
