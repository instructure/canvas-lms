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

import React, {useCallback, useEffect, useState} from 'react'

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

import {useScope as useI18nScope} from '@canvas/i18n'

import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

import {
  batchUpdateAllModulesApiCall,
  cancelBatchUpdate,
  fetchAllItemPublishedStates,
  monitorProgress,
  updateModulePendingPublishedStates,
  ProgressResult,
} from '../utils/publishAllModulesHelper'
import {disableContextModulesPublishMenu} from '../utils/publishOneModuleHelper'
import ContextModulesPublishModal from './ContextModulesPublishModal'

const I18n = useI18nScope('context_modules_publish_menu')

interface Props {
  readonly courseId: string | number
  readonly runningProgressId: string | number | null
  readonly disabled: boolean
}

// TODO: remove and replace MenuItem with Menu.Item below when on v8
const {Item: MenuItem} = Menu as any

const ContextModulesPublishMenu = ({courseId, runningProgressId, disabled}: Props) => {
  const [isPublishing, setIsPublishing] = useState(!!runningProgressId)
  const [isCanceling, setIsCanceling] = useState(false)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const [shouldPublishModules, setShouldPublishModules] = useState<boolean | undefined>(undefined)
  const [shouldSkipModuleItems, setShouldSkipModuleItems] = useState(false)
  const [progressId, setProgressId] = useState(runningProgressId)
  const [currentProgress, setCurrentProgress] = useState<ProgressResult | undefined>(undefined)
  const [modelsReady, setModelsReady] = useState<boolean>(false)

  const updateCurrentProgress_cb = useCallback(updateCurrentProgress, [shouldPublishModules])

  useEffect(() => {
    window.addEventListener('module-publish-models-ready', () => {
      setModelsReady(true)
    })
  }, [])

  // if the module page is loaded while a publish is in progress,
  // initialize the UI accordingly
  useEffect(() => {
    if (modelsReady && isPublishing) {
      updateModulePendingPublishedStates(true)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [modelsReady])

  useEffect(() => {
    if (progressId) {
      monitorProgress(progressId, updateCurrentProgress_cb, onProgressFail)
    }
  }, [progressId, updateCurrentProgress_cb])

  const statusIcon = () => {
    if (isPublishing) {
      return <Spinner renderTitle={I18n.t('Loading')} size="x-small" />
    } else {
      return <IconPublishLine size="x-small" color="success" />
    }
  }

  const reset = () => {
    disableContextModulesPublishMenu(false)
    setIsPublishing(false)
    setProgressId(null)
    setCurrentProgress(undefined)
    setIsModalOpen(false)
  }

  const refreshPublishStates = () => {
    return fetchAllItemPublishedStates(courseId)
      .then(() => {
        showFlashAlert({
          message: I18n.t('Modules updated'),
          type: 'success',
          err: null,
        })
      })
      .catch(error =>
        showFlashAlert({
          message: I18n.t(
            'There was an error updating module and items publish status. Try refreshing the page.'
          ),
          type: 'error',
          err: error,
        })
      )
      .finally(() => reset())
  }

  const onPublishComplete = () => {
    // eslint-disable-next-line promise/catch-or-return
    refreshPublishStates().then(() => reset())
  }

  function updateCurrentProgress(progress) {
    if (progress.workflow_state === 'completed') {
      onPublishComplete()
    } else if (progress.workflow_state === 'failed') {
      showFlashAlert({
        message: I18n.t('Your publishing job did not complete.'),
        err: undefined,
        type: 'error',
      })
      refreshPublishStates()
    } else {
      setCurrentProgress(progress)
      if (progress.workflow_state === 'running' && progress.completion > 0) {
        showFlashAlert({
          message: I18n.t('Publishing progress is %{progress} percent complete', {
            progress: Math.round(progress.completion),
          }),
          type: 'info',
          err: undefined,
          srOnly: true,
        })
      }
    }
  }

  function onProgressFail(error) {
    showFlashAlert({
      message: I18n.t(
        "Something went wrong monitoring the work's progress. Try refreshing the page."
      ),
      err: error,
      type: 'error',
    })
  }

  const onPublishFail = error => {
    reset()
    updateModulePendingPublishedStates(false)
    showFlashAlert({
      message: I18n.t('There was an error while saving your changes'),
      err: error,
      type: 'error',
    })
  }

  const onCancelComplete = (error = undefined) => {
    setIsCanceling(false)
    setIsPublishing(false)
    if (error) {
      onPublishFail(error)
    }
  }

  const handleCancel = () => {
    setIsModalOpen(false)
    cancelBatchUpdate(currentProgress, onCancelComplete)
    setIsCanceling(true)
    setCurrentProgress(undefined)
  }

  function handlePublish() {
    if (isPublishing) return
    setIsPublishing(true)
    updateModulePendingPublishedStates(true)
    batchUpdateAllModulesApiCall(courseId, shouldPublishModules, shouldSkipModuleItems)
      .then(result => {
        setProgressId(result.json.progress.progress.id)
        setCurrentProgress(result.json.progress.progress)
      })
      .catch(error => {
        onPublishFail(error)
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
        show={isPublishing ? false : undefined}
        disabled={disabled}
      >
        <MenuItem onClick={publishAll}>
          <IconPublishSolid color="success" /> {I18n.t('Publish all modules and items')}
        </MenuItem>
        <MenuItem onClick={publishModuleOnly}>
          <IconPublishSolid color="success" /> {I18n.t('Publish modules only')}
        </MenuItem>
        <MenuItem onClick={unpublishAll}>
          <IconUnpublishedLine /> {I18n.t('Unpublish all modules and items')}
        </MenuItem>
      </Menu>
      <ContextModulesPublishModal
        isOpen={isModalOpen}
        onCancel={handleCancel}
        onClose={() => setIsModalOpen(false)}
        onPublish={handlePublish}
        isCanceling={isCanceling}
        isPublishing={isPublishing}
        skippingItems={shouldSkipModuleItems}
        progressId={progressId}
        progressCurrent={currentProgress}
        title={modalTitle()}
      />
    </View>
  )
}

export default ContextModulesPublishMenu
