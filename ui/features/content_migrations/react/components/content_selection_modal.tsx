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
import {Modal} from '@instructure/ui-modal'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Alert} from '@instructure/ui-alerts'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Spinner} from '@instructure/ui-spinner'
import {useScope as useI18nScope} from '@canvas/i18n'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {
  TreeSelector,
  type CheckboxTreeNode,
  type CheckboxState,
  type ItemType,
} from '@canvas/content-migrations'
import type {ContentMigrationItem, GenericItemResponse} from './types'
import {mapToCheckboxTreeNodes, generateSelectiveDataResponse, responseToItem} from './utils'

export type Item = {
  id: string
  label: string
  type: ItemType
  migrationId?: string
  children?: Item[]
  linkedId?: string
  checkboxState: CheckboxState
}

type SelectiveDataResponse = (GenericItemResponse & {count?: number; sub_items_url?: string})[]

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
  const [checkboxTreeNodes, setCheckboxTreeNodes] = useState<Record<string, CheckboxTreeNode>>({})
  const [hasErrors, setHasErrors] = useState<boolean>(false)
  const [isLoading, setIsLoading] = useState<boolean>(false)

  const I18n = useI18nScope('content_migrations_redesign')

  const getChildSelectiveData = async (
    response: SelectiveDataResponse,
    setHasErrors: (hasErrors: boolean) => void,
  ): Promise<Record<string, CheckboxTreeNode>> => {
    const rootItems: Item[] = []

    for (const {type, title, property, sub_items, count, sub_items_url, migration_id} of response) {
      const rootItem = responseToItem({
        type,
        title,
        property,
        sub_items,
        migration_id,
      }, I18n)

      if (sub_items_url && count) {
         
        const {json} = await doFetchApi<GenericItemResponse[]>({
          path: sub_items_url,
          method: 'GET',
        })
        if (!json) {
          setHasErrors(true)
          continue
        }
        rootItem.label = I18n.t('%{title} (%{count})', {title, count})
        rootItem.children = json.map(jsonElement => responseToItem(jsonElement, I18n))
      }
      rootItems.push(rootItem)
    }

    return mapToCheckboxTreeNodes(rootItems)
  }

  const handleEntered = useCallback(async () => {
    setHasErrors(false)
    setIsLoading(true)
    try {
      const {json} = await doFetchApi<SelectiveDataResponse>({
        path: `/api/v1/courses/${courseId}/content_migrations/${migration.id}/selective_data`,
        method: 'GET',
      })
      if (!json) {
        setHasErrors(true)
        setCheckboxTreeNodes({})
        return
      }
      const mappedItems = await getChildSelectiveData(json, setHasErrors)
      setCheckboxTreeNodes(mappedItems)
    } catch {
      setHasErrors(true)
    } finally {
      setIsLoading(false)
    }
  }, [courseId, getChildSelectiveData, migration.id])

  const handleSubmit = () => {
    doFetchApi({
      path: `/api/v1/courses/${courseId}/content_migrations/${migration.id}`,
      method: 'PUT',
      body: generateSelectiveDataResponse(migration.id, ENV.current_user_id!, checkboxTreeNodes),
    })
      .then(() => {
        updateMigrationItem?.(migration.id)
        setOpen(false)
      })
      .catch(() => setOpen(false))
  }

  if (!courseId || migration.workflow_state !== 'waiting_for_select') return null

  let content
  if (Object.keys(checkboxTreeNodes).length > 0 && !hasErrors && !isLoading) {
    content = <TreeSelector checkboxTreeNodes={checkboxTreeNodes} onChange={setCheckboxTreeNodes} />
  } else if (hasErrors) {
    content = (
      <Alert variant="error" margin="small">
        {I18n.t('Failed to fetch content for import.')}
      </Alert>
    )
  } else if (isLoading) {
    content = (
      <View display="block" padding="large" textAlign="center">
        <Spinner renderTitle={() => I18n.t('Loading content for import.')} />
      </View>
    )
  } else if (Object.keys(checkboxTreeNodes).length === 0) {
    content = (
      <View display="block" padding="0 0 xx-large">
        <Text>
          {I18n.t(
            'This file appears to be empty. Do you still want to proceed with content selection?'
          )}
        </Text>
      </View>
    )
  }

  return (
    <>
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
          <Button onClick={() => setOpen(false)} margin="0 x-small 0 0">
            {I18n.t('Cancel')}
          </Button>
          <Button
            color="primary"
            interaction={hasErrors || isLoading ? 'disabled' : 'enabled'}
            onClick={handleSubmit}
          >
            {I18n.t('Select Content')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}
