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
// @ts-ignore
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  IconSettingsLine,
  IconSyllabusLine,
  IconModuleLine,
  IconHourGlassLine,
  IconAssignmentLine,
  IconQuizLine,
  IconCollectionLine,
  IconDiscussionLine,
  IconNoteLine,
  IconLtiLine,
  IconAnnouncementLine,
  IconCalendarDaysLine,
  IconRubricLine,
  IconGroupLine,
  IconOutcomesLine,
  IconStandardsLine,
  IconFolderLine,
  IconDocumentLine,
} from '@instructure/ui-icons'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {CollapsableList, type Item} from '@canvas/content-migrations'
import type {ContentMigrationItem, ContentMigrationWorkflowState} from './types'

const I18n = useI18nScope('content_migrations_redesign')

const ICONS: {[key: string]: any} = {
  course_settings: IconSettingsLine,
  syllabus_body: IconSyllabusLine,
  course_paces: IconHourGlassLine,
  context_modules: IconModuleLine,
  assignments: IconAssignmentLine,
  quizzes: IconQuizLine,
  assessment_question_banks: IconCollectionLine,
  discussion_topics: IconDiscussionLine,
  wiki_pages: IconNoteLine,
  context_external_tools: IconLtiLine,
  tool_profiles: IconLtiLine,
  announcements: IconAnnouncementLine,
  calendar_events: IconCalendarDaysLine,
  rubrics: IconRubricLine,
  groups: IconGroupLine,
  learning_outcomes: ENV.SHOW_SELECTABLE_OUTCOMES_IN_IMPORT ? IconOutcomesLine : IconStandardsLine,
  learning_outcome_groups: IconFolderLine,
  attachments: IconDocumentLine,
  assignment_groups: IconFolderLine,
  folders: IconFolderLine,
  blueprint_settings: IconSettingsLine,
}

type GenericItemResponse = {
  property: string
  title: string
  type: string
  sub_items?: GenericItemResponse[]
}

type SelectiveDataRequest = {
  id: string
  user_id: string
  copy: {[key: string]: string | {[key: string]: string}}
  workflow_state: ContentMigrationWorkflowState
}

type SelectiveDataResponse = (GenericItemResponse & {count?: number; sub_items_url?: string})[]

const responseToItem = ({type, title, property, sub_items}: GenericItemResponse): Item => ({
  id: property,
  label: title,
  icon: ICONS[type],
  children: sub_items ? sub_items.map(responseToItem) : undefined,
})

const mapSelectiveDataResponse = async (response: SelectiveDataResponse): Promise<Item[]> => {
  const rootItems: Item[] = []

  for (const {type, title, property, sub_items, count, sub_items_url} of response) {
    const rootItem = responseToItem({
      type,
      title,
      property,
      sub_items,
    })

    if (sub_items_url && count) {
      // eslint-disable-next-line no-await-in-loop
      const {json}: {json: GenericItemResponse[]} = await doFetchApi({
        path: sub_items_url,
        method: 'GET',
      })
      rootItem.label = I18n.t('%{title} (%{count})', {title, count})
      rootItem.children = json.map(responseToItem)
    }
    rootItems.push(rootItem)
  }
  return rootItems
}

const generateSelectiveDataResponse = (
  migrationId: string,
  userId: string,
  selectedProperties: string[]
): SelectiveDataRequest => {
  const copy: {[key: string]: any} = {}
  // This regex is used to get the copy key and sub-keys to use it to build the json
  // Example: copy[all_course_settings], copy[attachments][migration_abc123]
  const propertyRegex = /copy\[(.*?)\](?:\[(.*?)\])?/i
  selectedProperties.forEach(property => {
    const matches = property.match(propertyRegex)
    if (matches) {
      const key = matches[1]
      const subKey = matches[2]
      if (!subKey) {
        copy[key] = '1'
      } else {
        if (!copy[key]) copy[key] = {}
        copy[key][subKey] = '1'
      }
    }
  })
  return {id: migrationId, user_id: userId, workflow_state: 'waiting_for_select', copy}
}

type ContentSelectionModalProps = {
  courseId: string | undefined
  migration: ContentMigrationItem
  updateMigrationItem?: (migrationId: string) => void
}

export const ContentSelectionModal = ({
  courseId,
  migration,
  updateMigrationItem,
}: ContentSelectionModalProps) => {
  const [open, setOpen] = useState(false)
  const [selectedProperties, setSelectedProperties] = useState<Array<string>>([])
  const [items, setItems] = useState<Item[]>([])
  const [hasErrors, setHasErrors] = useState<boolean>(false)

  const handleEntered = useCallback(() => {
    doFetchApi({
      path: `/api/v1/courses/${courseId}/content_migrations/${migration.id}/selective_data`,
      method: 'GET',
    })
      .then(({json}: {json: SelectiveDataResponse}) => mapSelectiveDataResponse(json))
      .then((mappedItems: Item[]) => setItems(mappedItems))
      .catch(() => setHasErrors(true))
  }, [courseId, migration.id])

  const handleSubmit = () => {
    doFetchApi({
      path: `/api/v1/courses/${courseId}/content_migrations/${migration.id}`,
      method: 'PUT',
      body: generateSelectiveDataResponse(migration.id, ENV.current_user_id!, selectedProperties),
    })
      .then(() => {
        updateMigrationItem?.(migration.id)
        setOpen(false)
      })
      .catch(() => setOpen(false))
  }

  if (!courseId || migration.workflow_state !== 'waiting_for_select') return null

  let content
  if (items.length > 0 && !hasErrors) {
    content = (
      <CollapsableList
        items={items}
        onChange={newSelectedProperties => setSelectedProperties(newSelectedProperties)}
      />
    )
  } else if (hasErrors) {
    content = (
      <Alert variant="error" margin="small">
        {I18n.t('Failed to fetch content for import.')}
      </Alert>
    )
  } else {
    content = (
      <View display="block" padding="large" textAlign="center">
        <Spinner renderTitle={() => I18n.t('Loading content for import.')} />
      </View>
    )
  }

  return (
    <>
      {/* @ts-ignore */}
      <Button size="small" color="primary" onClick={() => setOpen(true)}>
        {I18n.t('Select content')}
      </Button>
      <Modal
        open={open}
        onDismiss={() => setOpen(false)}
        size="medium"
        label={I18n.t('Select Content for Import')}
        shouldCloseOnDocumentClick={true}
        onEnter={handleEntered}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={() => setOpen(false)}
            screenReaderLabel={I18n.t('Close')}
          />
          <Heading>{I18n.t('Select Content for Import')}</Heading>
        </Modal.Header>
        <Modal.Body>{content}</Modal.Body>
        <Modal.Footer>
          {/* @ts-ignore */}
          <Button onClick={() => setOpen(false)} margin="0 x-small 0 0">
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            interaction={selectedProperties.length > 0 ? 'enabled' : 'disabled'}
            // @ts-ignore
            onClick={handleSubmit}
          >
            {I18n.t('Select Content')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}
