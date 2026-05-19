/*
 * Copyright (C) 2026 - present Instructure, Inc.
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

import {useScope as createI18nScope} from '@canvas/i18n'
import {useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Modal} from '@instructure/ui-modal'
import {Text} from '@instructure/ui-text'
import {Heading} from '@instructure/ui-heading'
import {IconDeactivateUserLine} from '@instructure/ui-icons'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {Flex} from '@instructure/ui-flex'
import {showFlashError, showFlashSuccess} from '@instructure/platform-alerts'
import {raw} from '@instructure/html-escape'

const I18n = createI18nScope('terminate_sessions')

interface TerminateSessionsProps {
  user: {
    id: string
    name: string
  }
}

export default function TerminateSessions({user}: TerminateSessionsProps) {
  const [isLoading, setIsLoading] = useState(false)
  const [isModalOpen, setIsModalOpen] = useState(false)
  const closeText = I18n.t('Close')
  const terminateText = I18n.t('Terminate all sessions for this user')

  const closeModal = () => {
    setIsModalOpen(false)
  }

  const handleSessionTermination = async () => {
    try {
      setIsLoading(true)

      await doFetchApi({path: `/api/v1/users/${user.id}/sessions`, method: 'DELETE'})

      showFlashSuccess(I18n.t('All sessions have been terminated successfully.'))()
    } catch (error) {
      console.error('Error terminating sessions:', error)

      showFlashError(I18n.t('An error occurred while terminating sessions. Please try again.'))()
    } finally {
      setIsLoading(false)
      closeModal()
    }
  }

  return (
    <>
      <Button
        display="block"
        color="secondary"
        textAlign="start"
        renderIcon={<IconDeactivateUserLine />}
        onClick={() => setIsModalOpen(true)}
      >
        {terminateText}
      </Button>
      <Modal
        open={isModalOpen}
        onDismiss={() => setIsModalOpen(false)}
        size="medium"
        label={terminateText}
        shouldCloseOnDocumentClick={false}
      >
        <Modal.Header>
          <CloseButton
            placement="end"
            offset="small"
            onClick={closeModal}
            screenReaderLabel={closeText}
          />
          <Heading>{terminateText}</Heading>
        </Modal.Header>
        <Modal.Body>
          <Flex direction="column" gap="small">
            <Text
              dangerouslySetInnerHTML={{
                __html: raw(
                  I18n.t(
                    'This will terminate all user sessions for *%{userName}*. This includes all browser-based sessions and all access tokens, including manually generated ones and Canvas mobile apps.',
                    {userName: user.name, wrapper: '<b>$1</b>'},
                  ),
                ),
              }}
            />
            <Text>
              {I18n.t(
                'The user can immediately re-authenticate to access Canvas again if they have valid credentials. This action cannot be undone. All integrations will need to be re-authorized individually by the user to restore access. ',
              )}
            </Text>
          </Flex>
        </Modal.Body>
        <Modal.Footer>
          <Button color="secondary" onClick={closeModal}>
            {closeText}
          </Button>
          <Button
            color="danger"
            margin="0 0 0 buttons"
            onClick={handleSessionTermination}
            disabled={isLoading}
          >
            {isLoading ? I18n.t('Confirming...') : I18n.t('Confirm')}
          </Button>
        </Modal.Footer>
      </Modal>
    </>
  )
}
