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
import React, {useEffect, useState} from 'react'
import ReactDOM from 'react-dom'

import {
  IconMiniArrowDownLine,
  IconPublishLine,
  IconPublishSolid,
  IconUnpublishedLine,
} from '@instructure/ui-icons'
import {Button} from '@instructure/ui-buttons'
import {Menu} from '@instructure/ui-menu'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'

import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {initPublishButton} from '@canvas/context-modules/jquery/utils'
import ContextModulesPublishIcon from '@canvas/context-modules-publish-icon/ContextModulesPublishIcon'
import ContextModulesPublishModal from './ContextModulesPublishModal'

const I18n = useI18nScope('context_modules_publish_menu')

interface Props {
  readonly courseId: string
  readonly runningProgressId: string | null
  readonly disabled: boolean
}

const ContextModulesPublishMenu: React.FC<Props> = ({courseId, runningProgressId, disabled}) => {
  const [isPublishing, setIsPublishing] = useState(false)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [shouldPublishModules, setShouldPublishModules] = useState(false)
  const [shouldSkipModuleItems, setShouldSkipModuleItems] = useState(false)
  const [progressId, setProgressId] = useState(runningProgressId)
  const [isDisabled] = useState(disabled)

  useEffect(() => {
    if (progressId) {
      setIsPublishing(true)
      setIsModalOpen(true)
    } else {
      setIsPublishing(false)
    }
  }, [progressId])

  const statusIcon = () => {
    if (isPublishing) {
      return <Spinner renderTitle={I18n.t('Loading')} size="x-small" />
    } else {
      return <IconPublishLine size="x-small" color="success" />
    }
  }

  const moduleIds = (): Array<Number> => {
    const ids = new Set<Number>()
    const dataModules = document.querySelectorAll(
      '.context_module[data-module-id]'
    ) as NodeListOf<HTMLElement> // eslint-disable-line no-undef
    dataModules.forEach(el => {
      if (el.id === undefined) return

      const id = parseInt(el.id.replace(/\D/g, ''), 10)
      ids.add(id)
    })

    return [...ids.values()].filter(Number)
  }

  const batchUpdateApiCall = () => {
    if (isPublishing) return

    const path = `/api/v1/courses/${courseId}/modules`

    const event = shouldPublishModules ? 'publish' : 'unpublish'
    const async = true

    setIsPublishing(true)
    return doFetchApi({
      path,
      method: 'PUT',
      body: {
        module_ids: moduleIds(),
        event,
        skip_content_tags: shouldSkipModuleItems,
        async,
      },
    })
      .then(result => {
        return result
      })
      .then(result => {
        if (result.json.progress) {
          setProgressId(result.json.progress.progress.id)
        }
      })
      .catch(error => showFlashError(I18n.t('There was an error while saving your changes'))(error))
  }

  const onPublishComplete = () => {
    updateModuleStates()
    setIsPublishing(false)
    setProgressId(null)
    showFlashSuccess(I18n.t('Modules updated'))()
  }

  const updateModuleStates = (nextLink?: string) => {
    doFetchApi({
      path: nextLink || `/api/v1/courses/${courseId}/modules?include[]=items`,
      method: 'GET',
    })
      .then(({json, link}) => {
        json.forEach((module: any) => {
          updateModulePublishedState(module.published, module.id)
          module.items.forEach((item: any) => {
            updateModuleItemPublishedState(item.id, item.published)
          })
        })
        if (link?.next) {
          updateModuleStates(link.next.url)
        }
      })
      .catch(error => showFlashError(I18n.t('There was an error while saving your changes'))(error))
  }

  const updateModulePublishedState = (isPublished: boolean, moduleId: Number) => {
    const publishIcon = document.querySelector(
      `#context_module_${moduleId} .module-publish-icon`
    ) as HTMLElement | null
    if (publishIcon) {
      // Update the new state of the module then we unmount the component to render the newly changed state
      publishIcon.dataset.published = isPublished.toString()
      ReactDOM.unmountComponentAtNode(publishIcon)
      ReactDOM.render(
        <ContextModulesPublishIcon
          courseId={publishIcon.dataset.courseId}
          moduleId={publishIcon.dataset.moduleId}
          published={publishIcon.dataset.published === 'true'}
        />,
        publishIcon
      )
    }
  }

  const updateModuleItemPublishedState = (itemId: Number, isPublished: boolean) => {
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
    setShouldPublishModules(false)
    setShouldSkipModuleItems(false)
    setIsModalOpen(true)
  }

  const publishAll = () => {
    setShouldPublishModules(true)
    setShouldSkipModuleItems(false)
    setIsModalOpen(true)
  }

  const publishModuleOnly = () => {
    setShouldPublishModules(true)
    setShouldSkipModuleItems(true)
    setIsModalOpen(true)
  }

  const modalTitle = () => {
    if (shouldPublishModules) {
      if (shouldSkipModuleItems) {
        return I18n.t('Publish modules only')
      } else {
        return I18n.t('Publish all modules and items')
      }
    } else {
      return I18n.t('Unpublish all modules and items')
    }
  }

  return (
    <View textAlign="center">
      <Menu
        placement="bottom"
        trigger={
          <Button renderIcon={statusIcon}>
            {I18n.t('Publish All')} <IconMiniArrowDownLine size="x-small" />
          </Button>
        }
        disabled={isPublishing || isDisabled}
      >
        <Menu.Item onClick={publishAll}>
          <IconPublishSolid color="success" /> {I18n.t('Publish all modules and items')}
        </Menu.Item>
        <Menu.Item onClick={publishModuleOnly}>
          <IconPublishSolid color="success" /> {I18n.t('Publish modules only')}
        </Menu.Item>
        <Menu.Item onClick={unpublishAll}>
          <IconUnpublishedLine /> {I18n.t('Unpublish all modules and items')}
        </Menu.Item>
      </Menu>
      <ContextModulesPublishModal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        onPublish={batchUpdateApiCall}
        onPublishComplete={onPublishComplete}
        progressId={progressId}
        title={modalTitle()}
      />
    </View>
  )
}

export default ContextModulesPublishMenu
