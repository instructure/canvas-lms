// @ts-nocheck
/*
 * Copyright (C) 2022 - present Instructure, Inc.
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

import $ from 'jquery'
import React, {useState} from 'react'

import {IconMiniArrowDownLine, IconPublishSolid, IconUnpublishedLine} from '@instructure/ui-icons'
import {IconButton} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import {showFlashError, showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'

import {initPublishButton} from '@canvas/context-modules/jquery/utils'

const I18n = useI18nScope('context_modules_publish_icon')

interface Props {
  readonly courseId: string
  readonly moduleId: string
  readonly published: Boolean
}

const ContextModulesPublishIcon: React.FC<Props> = ({courseId, moduleId, published}) => {
  const [isPublished, setIsPublished] = useState(published)
  const [isPublishing, setIsPublishing] = useState(false)
  const [loadingMessage, setLoadingMessage] = useState(null)

  const statusIcon = () => {
    const iconStyles = {
      paddingLeft: '0.25rem',
    }
    if (isPublishing) {
      return <Spinner renderTitle={loadingMessage} size="x-small" />
    } else if (isPublished) {
      return (
        <>
          <IconPublishSolid size="x-small" color="success" style={iconStyles} />
          <IconMiniArrowDownLine size="x-small" />
        </>
      )
    } else {
      return (
        <>
          <IconUnpublishedLine size="x-small" color="secondary" style={iconStyles} />
          <IconMiniArrowDownLine size="x-small" />
        </>
      )
    }
  }

  const updateApiCall = (
    newPublishedState: boolean,
    skipModuleItems: boolean,
    successMessage: string
  ) => {
    if (isPublishing) return

    const path = `/api/v1/courses/${courseId}/modules/${moduleId}`

    setIsPublishing(true)
    return doFetchApi({
      path,
      method: 'PUT',
      body: {
        module: {
          published: newPublishedState,
          skip_content_tags: skipModuleItems,
        },
      },
    })
      .then(result => {
        setIsPublished(result.json.published)
        showFlashAlert({
          message: successMessage,
          type: 'success',
          srOnly: true,
        })
        fetchModuleItemPublishedState()
      })
      .catch(error => showFlashError(I18n.t('There was an error while saving your changes'))(error))
      .finally(() => setIsPublishing(false))
  }

  const fetchModuleItemPublishedState = (nextLink?: string) => {
    doFetchApi({
      path: nextLink || `/api/v1/courses/${courseId}/modules/${moduleId}/items`,
      method: 'GET',
    })
      .then(({json, link}) => {
        json.forEach((item: any) => {
          updateModuleItemPublishedState(item.id, item.published)
        })
        if (link?.next) {
          fetchModuleItemPublishedState(link.next.url)
        }
      })
      .catch(error => showFlashError(I18n.t('There was an error while saving your changes'))(error))
  }

  const updateModuleItemPublishedState = (itemId: string, isPublished: boolean) => {
    const itemRow = document.querySelector(`#context_module_item_${itemId}`) as HTMLElement | null
    if (itemRow) {
      itemRow.querySelector('.ig-row')?.classList.toggle('ig-published', isPublished)
      const publishIcon = $(itemRow.querySelector('.publish-icon'))
      if (publishIcon) {
        publishIcon.data('published', isPublished)
        initPublishButton(publishIcon)
      }
    }
  }

  const unpublishAll = () => {
    setLoadingMessage(I18n.t('Unpublishing module and items'))
    updateApiCall(false, false, I18n.t('Module and items unpublished'))
  }

  const publishAll = () => {
    setLoadingMessage(I18n.t('Publishing module and items'))
    updateApiCall(true, false, I18n.t('Module and items published'))
  }

  const publishModuleOnly = () => {
    setLoadingMessage(I18n.t('Publishing module'))
    updateApiCall(true, true, I18n.t('Module published'))
  }

  return (
    <View textAlign="center">
      <Menu
        placement="bottom"
        show={isPublishing ? false : undefined}
        trigger={
          <IconButton withBorder={false} screenReaderLabel={I18n.t('Module publish menu')}>
            {statusIcon()}
          </IconButton>
        }
      >
        <Menu.Item onClick={publishAll}>
          <IconPublishSolid color="success" /> {I18n.t('Publish module and all items')}
        </Menu.Item>
        <Menu.Item onClick={publishModuleOnly}>
          <IconPublishSolid color="success" /> {I18n.t('Publish module only')}
        </Menu.Item>
        <Menu.Item onClick={unpublishAll}>
          <IconUnpublishedLine /> {I18n.t('Unpublish module and all items')}
        </Menu.Item>
      </Menu>
    </View>
  )
}

export default ContextModulesPublishIcon
