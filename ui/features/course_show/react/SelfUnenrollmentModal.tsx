/*
 * Copyright (C) 2025 - present Instructure, Inc.
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

import {useState} from 'react'
import {Modal} from '@instructure/ui-modal'
import {useScope as createI18nScope} from '@canvas/i18n'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Heading} from '@instructure/ui-heading'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashError, showFlashSuccess} from '@canvas/alerts/react/FlashAlert'
import {Spinner} from '@instructure/ui-spinner'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('self_unenrollment_modal')

interface SelfUnenrollmentModalProps {
  unenrollmentApiUrl: string
  onClose: VoidFunction
}

const SelfUnenrollmentModal = ({unenrollmentApiUrl, onClose}: SelfUnenrollmentModalProps) => {
  const [isLoading, setIsLoading] = useState(false)
  const title = I18n.t('Confirm Unenrollment')
  const closeButtonText = I18n.t('Close')

  const unnenrollUser = async () => {
    try {
      setIsLoading(true)

      await doFetchApi({
        path: unenrollmentApiUrl,
        method: 'POST',
      })

      showFlashSuccess(I18n.t('You have been unenrolled from the course.'))()

      setTimeout(() => {
        window.location.reload()
      }, 500)
    } catch (error) {
      console.error('Error unenrolling from course:', error)

      showFlashError(I18n.t('There was an error unenrolling from the course. Please try again.'))()

      setIsLoading(false)
    }
  }

  return (
    <Modal
      open={true}
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
          screenReaderLabel={closeButtonText}
        />
        <Heading>{title}</Heading>
      </Modal.Header>
      <Modal.Body>
        {isLoading ? (
          <Flex justifyItems="center">
            <Spinner renderTitle={I18n.t('Waiting for unenrollment...')} />
          </Flex>
        ) : (
          I18n.t(
            'Are you sure you want to drop this course? You will no longer be able to see the course roster or communicate directly with the teachers, and you will no longer see course events in your stream and as notifications.',
          )
        )}
      </Modal.Body>
      <Modal.Footer>
        <Button
          type="button"
          color="secondary"
          onClick={onClose}
          margin="0 x-small 0 0"
          disabled={isLoading}
        >
          {closeButtonText}
        </Button>
        <Button type="button" color="primary" onClick={unnenrollUser} disabled={isLoading}>
          {I18n.t('Drop this course')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default SelfUnenrollmentModal
