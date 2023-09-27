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
import {View} from '@instructure/ui-view'
import {MigratorSpecificForm} from './migrator_specific_form'
import {GeneralMigrationControls} from './general_migration_controls'
import {ContentMigrationItem, Migrator, submitMigrationProps} from './types'

const I18n = useI18nScope('content_migrations_redesign')

// TODO: Doing this to avoid TS2339 errors-- remove once we're on InstUI 8
const {Option: SimpleSelectOption} = SimpleSelect as any

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

  useEffect(() => {
    doFetchApi({
      path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations/migrators`,
    })
      .then((response: any) => {
        setMigrators(
          response.json.sort((a: Migrator, _b: Migrator) => {
            if (a.type === 'course_copy_importer' || a.type === 'canvas_cartridge_importer') {
              return -1
            }
            return 0
          })
        )
      })
      .catch(showFlashError(I18n.t("Couldn't load migrators")))
  }, [])

  const handleMigratorChange = (migrator_type: string) => {
    setChosenMigrator(migrator_type)
  }

  const submitMigration = async ({
    selectiveImport,
    importAsNewQuizzes,
    adjustDates,
  }: submitMigrationProps) => {
    const requestBody = {
      course_id: window.ENV.COURSE_ID,
      migration_type: chosenMigrator,
      settings: {
        import_quizzes_next: importAsNewQuizzes,
        source_course_id: sourceCourse,
      },
      selective_import: selectiveImport,
      date_shift_options: adjustDates,
    }
    const {json} = (await doFetchApi({
      method: 'POST',
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations`,
      body: requestBody,
    })) as {json: ContentMigrationItem} // TODO: remove type assertion once doFetchApi is typed
    setMigrations([json].concat(migrations))
    setChosenMigrator('empty')
  }

  return (
    <View as="div" padding="0 x-small 0 0" margin="0 x-small 0 0">
      <View as="div" maxWidth="22.5rem">
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
      <MigratorSpecificForm migrator={chosenMigrator} setSourceCourse={setSourceCourse} />
      {chosenMigrator !== 'empty' ? (
        <GeneralMigrationControls submitMigration={submitMigration} />
      ) : null}
    </View>
  )
}

export default ContentMigrationsForm
