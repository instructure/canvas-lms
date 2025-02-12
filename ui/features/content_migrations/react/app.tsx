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

import React, {useCallback, useEffect, useState} from 'react'
import {useScope as createI18nScope} from '@canvas/i18n'
import ContentMigrationsForm from './components/migrations_form'
import ContentMigrationsTable from './components/migrations_table'
import type {ContentMigrationItem, UpdateMigrationItemType} from './components/types'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'

const I18n = createI18nScope('content_migrations_redesign')

type MigrationsResponse = {json: ContentMigrationItem[]}

export const App = () => {
  const [migrations, setMigrations] = useState<ContentMigrationItem[]>([])
  const [isLoading, setIsLoading] = useState(false)
  useEffect(() => {
    setIsLoading(true)
    doFetchApi({
      path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations`,
      params: {per_page: 25},
    })
      // @ts-expect-error
      .then((response: MigrationsResponse) => {
        setMigrations(_prevMigrations => response.json)
      })
      .catch(showFlashError(I18n.t("Couldn't load previous content migrations")))
      .finally(() => setIsLoading(false))
  }, [setMigrations])

  const updateMigrationItem: UpdateMigrationItemType = useCallback(
    async (migrationId: string, data: any, noXHR: boolean | undefined) => {
      if (noXHR) {
        setMigrations(prevMigrations =>
          prevMigrations.map((m: ContentMigrationItem) =>
            m.id === migrationId ? {...m, ...data} : m,
          ),
        )
      } else {
        try {
          const response = await doFetchApi<ContentMigrationItem>({
            path: `/api/v1/courses/${window.ENV.COURSE_ID}/content_migrations/${migrationId}`,
          })
          const json = response.json
          setMigrations(prevMigrations =>
            prevMigrations.map((m: ContentMigrationItem) =>
              m.id === migrationId ? {...json, ...data} : m,
            ),
          )
          return json
        } catch {
          showFlashError(I18n.t("Couldn't update content migrations"))
        }
      }
    },
    [setMigrations]
  )

  return (
    <>
      <ContentMigrationsForm setMigrations={setMigrations} />
      <ContentMigrationsTable migrations={migrations} isLoading={isLoading} updateMigrationItem={updateMigrationItem} />
    </>
  )
}

export default App
