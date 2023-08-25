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

import React from 'react'

import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {ProgressBar} from '@instructure/ui-progress'
import {AccessibleContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'

import {useScope as useI18nScope} from '@canvas/i18n'

import {ProgressResult} from '../utils/publishAllModulesHelper'

const I18n = useI18nScope('context_modules_publish_menu')

interface Props {
  readonly isOpen: boolean
  readonly onCancel: () => void
  readonly onClose: () => void
  readonly onDismiss: () => void
  readonly onPublish: () => void
  readonly isCanceling: boolean
  readonly isPublishing: boolean
  readonly skippingItems: boolean
  readonly progressId: string | number | null
  readonly progressCurrent?: ProgressResult
  readonly title: string
  readonly continueButtonId: string
  readonly mode: 'publish' | 'unpublish'
}
export const PUBLISH_STATUS_POLLING_MS = 1000

const ContextModulesPublishModal = ({
  isOpen,
  onCancel,
  onClose,
  onDismiss,
  onPublish,
  isCanceling,
  isPublishing,
  skippingItems,
  progressId,
  progressCurrent,
  title,
  continueButtonId,
  mode = 'publish',
}: Props) => {
  const handlePublish = () => {
    if (isPublishing) {
      onCancel()
    } else {
      onPublish()
    }
  }

  const progressBar = () => {
    if (!progressId) return null

    const labelText =
      mode === 'publish' ? I18n.t('Publishing Progress') : I18n.t('Unpublish Progress')

    return (
      <View as="div" padding="medium none">
        <Text size="small" weight="bold">
          {labelText}
        </Text>
        <ProgressBar
          screenReaderLabel={labelText}
          formatScreenReaderValue={({valueNow, valueMax}) => {
            return I18n.t('%val percent', {val: Math.round((valueNow / valueMax) * 100)})
          }}
          renderValue={({valueNow, valueMax}) => {
            return <Text size="small">{Math.round((valueNow / valueMax) * 100)}%</Text>
          }}
          valueMax={100}
          valueNow={progressCurrent?.completion || 0}
        />
      </View>
    )
  }

  return (
    <Modal
      open={isOpen}
      onClose={onClose}
      onDismiss={onDismiss}
      size="small"
      label={title}
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          onClick={onDismiss}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        <View as="div">
          <Text as="p">
            {I18n.t(
              'This process could take a few minutes. You may close the modal or navigate away from the page during this process.'
            )}
          </Text>
          <Text as="p">
            {skippingItems
              ? I18n.t(
                  'To discontinue processing, click the Stop button. Note: Modules that have already been processed will not be reverted to their previous state when the process is discontinued.'
                )
              : I18n.t(
                  'To discontinue processing, click the Stop button. Note: Modules and items that have already been processed will not be reverted to their previous state when the process is discontinued.'
                )}
          </Text>
        </View>
        {progressBar()}
      </Modal.Body>
      <Modal.Footer>
        <Button data-testid="close-button" onClick={onDismiss} margin="0 x-small 0 0">
          {I18n.t('Close')}
        </Button>
        <Button
          data-testid="publish-button"
          onClick={handlePublish}
          color="primary"
          disabled={isCanceling}
          id={continueButtonId}
        >
          {!isPublishing && isOpen ? (
            I18n.t('Continue')
          ) : (
            <AccessibleContent alt={I18n.t('Stop button. Click to discontinue processing.')}>
              {I18n.t('Stop')}
            </AccessibleContent>
          )}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default ContextModulesPublishModal
