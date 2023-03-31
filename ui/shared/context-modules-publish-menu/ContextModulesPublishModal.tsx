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

import React, {useEffect, useState} from 'react'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('context_modules_publish_menu')

interface Props {
  readonly isOpen: boolean
  readonly onClose: () => void
  readonly onPublish: () => void
  readonly onPublishComplete: (publish: boolean) => void
  readonly progressId: string | null
  readonly publishItems: boolean
  readonly title: string
}
export const PUBLISH_STATUS_POLLING_MS = 1000

const ContextModulesPublishModal: React.FC<Props> = ({
  isOpen,
  onClose,
  onPublish,
  onPublishComplete,
  progressId,
  publishItems,
  title,
}) => {
  const [isPublishing, setIsPublishing] = useState(false)
  const [isCanceling, setIsCanceling] = useState(false)
  const [progress, setProgress] = useState(null)
  const [progressCurrent, setProgressCurrent] = useState(0)

  useEffect(() => {
    if (progressId) {
      const interval = setInterval(pollProgress, PUBLISH_STATUS_POLLING_MS)
      return function cleanup() {
        clearInterval(interval)
      }
    }
  })

  const pollProgress = () => {
    if (!progressId) return
    if (
      progress &&
      (progress.workflow_state === 'completed' || progress.workflow_state === 'failed')
    )
      return

    const pollingLoop = () => {
      doFetchApi({
        path: `/api/v1/progress/${progressId}`,
      })
        .then(result => {
          return result
        })
        .then(result => {
          setProgress(result.json)
          setProgressCurrent(result.json.completion)
          if (result.json.workflow_state === 'completed') {
            handlePublishComplete()
          } else if (result.json.workflow_state === 'failed') {
            showFlashError(I18n.t('Your publishing job has failed.'))
            handlePublishComplete()
          }
        })
        .catch(error => {
          showFlashError(I18n.t('There was an error while saving your changes'))(error)
          setIsPublishing(false)
        })
    }
    return pollingLoop()
  }

  const handleCancel = () => {
    setIsCanceling(true)
    if (!progressId) return
    if (
      progress &&
      (progress.workflow_state === 'completed' || progress.workflow_state === 'failed')
    )
      return

    doFetchApi({
      path: `/api/v1/progress/${progressId}/cancel`,
      method: 'POST',
    })
      .then(result => {
        return result
      })
      .then(_result => {
        setProgress(null)
        window.location.reload() // We reload the page to get the current state of all the module items
      })
      .catch(error => {
        showFlashError(I18n.t('There was an error while saving your changes'))(error)
        setIsPublishing(false)
        setIsCanceling(false)
      })
  }

  const handlePublish = () => {
    if (isPublishing) {
      handleCancel()
    } else {
      setIsPublishing(true)
      onPublish()
    }
  }

  const handlePublishComplete = () => {
    // Remove progress id if one was loaded with page
    const publishMenu = document.getElementById('context-modules-publish-menu')
    if (publishMenu) {
      publishMenu.dataset.progressId = ''
    }
    onPublishComplete(publishItems)
    setProgress(null)
    setProgressCurrent(0)
    setIsPublishing(false)
    setIsCanceling(false)
    onClose()
  }

  const progressBar = () => {
    if (!progressId) return null

    return (
      <View as="div" padding="medium none">
        <Text size="small" weight="bold">
          {I18n.t('Publishing Progress')}
        </Text>
        <ProgressBar
          screenReaderLabel={I18n.t('Publishing Progress')}
          formatScreenReaderValue={({valueNow, valueMax}) => {
            return Math.round((valueNow / valueMax) * 100) + ' percent'
          }}
          renderValue={({valueNow, valueMax}) => {
            return <Text size="small">{Math.round((valueNow / valueMax) * 100)}%</Text>
          }}
          valueMax={100}
          valueNow={progressCurrent}
        />
      </View>
    )
  }

  return (
    <Modal
      open={isOpen}
      onDismiss={onClose}
      size="small"
      label={title}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onClose}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div">
          <Text>
            {I18n.t(
              'This process could take a few minutes. Hitting stop will stop the process, but items that have already been processed will not be reverted to their previous state.'
            )}
          </Text>
        </View>
        {progressBar()}
      </Modal.Body>
      <Modal.Footer>
        <Button data-testid="close-button" onClick={onClose} margin="0 x-small 0 0">
          {I18n.t('Close')}
        </Button>
        <Button
          data-testid="publish-button"
          onClick={handlePublish}
          color="primary"
          disabled={isCanceling}
        >
          {isPublishing ? I18n.t('Stop') : I18n.t('Continue')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default ContextModulesPublishModal
