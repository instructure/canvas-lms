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
}

const ContextModulesPublishMenu: React.FC<Props> = ({courseId, runningProgressId}) => {
  const [isPublishing, setIsPublishing] = useState(false)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [shouldPublishModules, setShouldPublishModules] = useState(false)
  const [shouldSkipModuleItems, setShouldSkipModuleItems] = useState(false)
  const [progressId, setProgressId] = useState(runningProgressId)

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

  const onPublishComplete = (isPublished: boolean) => {
    updateModulePublishedStates(isPublished, moduleIds())
    if (!shouldSkipModuleItems) {
      updateModuleItemPublishedStates(isPublished, moduleIds())
    }
    setIsPublishing(false)
    setProgressId(null)
    showFlashSuccess(I18n.t('Modules updated'))()
  }

  const updateModulePublishedStates = (isPublished: boolean, completedModuleIds: Array<Number>) => {
    completedModuleIds.forEach(moduleId => {
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
    })
  }

  const updateModuleItemPublishedStates = (
    isPublished: boolean,
    completedModuleIds: Array<Number>
  ) => {
    completedModuleIds.forEach(moduleId => {
      document.querySelectorAll(`#context_module_content_${moduleId} .ig-row`).forEach(element => {
        if (isPublished) {
          element.classList.add('ig-published')
        } else {
          element.classList.remove('ig-published')
        }
      })

      document
        .querySelectorAll(`#context_module_content_${moduleId} .publish-icon`)
        .forEach(element => {
          const publishIcon = $(element)
          publishIcon.data('published', isPublished)
          initPublishButton(publishIcon)
        })
    })
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
        disabled={isPublishing}
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
        publishItems={shouldPublishModules}
        title={modalTitle()}
      />
    </View>
  )
}

export default ContextModulesPublishMenu
