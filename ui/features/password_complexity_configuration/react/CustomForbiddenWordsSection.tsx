/*
 * Copyright (C) 2024 - present Instructure, Inc.
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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {Checkbox} from '@instructure/ui-checkbox'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {IconTrashLine, IconUploadSolid} from '@instructure/ui-icons'
import ForbiddenWordsFileUpload from './ForbiddenWordsFileUpload'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import type {PasswordSettingsResponse} from './types'
import {deleteForbiddenWordsFile} from './apiClient'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'

declare const ENV: GlobalEnv

const I18n = useI18nScope('password_complexity_configuration')

interface Props {
  setNewlyUploadedAttachmentId: (attachmentId: number | null) => void
  onCustomForbiddenWordsEnabledChange: (enabled: boolean) => void
}

interface ForbiddenWordsResponse {
  url: string
  display_name: string
}

export const fetchLatestForbiddenWords = async (
  attachmentId: number
): Promise<ForbiddenWordsResponse | null> => {
  const {status, data} = await executeApiRequest<ForbiddenWordsResponse>({
    path: `/api/v1/files/${attachmentId}`,
    method: 'GET',
  })
  return status === 200 ? data ?? null : null
}

const CustomForbiddenWordsSection = ({
  setNewlyUploadedAttachmentId,
  onCustomForbiddenWordsEnabledChange,
}: Props) => {
  const linkRef = useRef<HTMLAnchorElement | null>(null)
  const [forbiddenWordsUrl, setForbiddenWordsUrl] = useState<string | null>(null)
  const [forbiddenWordsName, setForbiddenWordsName] = useState<string | null>(null)
  const [fileModalOpen, setFileModalOpen] = useState(false)
  const [customForbiddenWordsEnabled, setCustomForbiddenWordsEnabled] = useState(false)
  const [commonPasswordsAttachmentId, setCommonPasswordsAttachmentId] = useState<number | null>(
    null
  )

  const handleForbiddenWordsToggle = () => {
    const newEnabledState = !customForbiddenWordsEnabled
    setCustomForbiddenWordsEnabled(newEnabledState)
    onCustomForbiddenWordsEnabledChange(newEnabledState)
  }

  const fetchAndSetForbiddenWords = useCallback(async () => {
    const {status, data: settingsResult} = await executeApiRequest<PasswordSettingsResponse>({
      path: `/api/v1/accounts/${ENV.DOMAIN_ROOT_ACCOUNT_ID}/settings`,
      method: 'GET',
    })
    if (status !== 200) {
      throw new Error('Failed to fetch current settings.')
    }

    const attachmentId = settingsResult.password_policy.common_passwords_attachment_id
    if (!attachmentId) {
      return
    }
    setCommonPasswordsAttachmentId(attachmentId)

    try {
      const data = await fetchLatestForbiddenWords(attachmentId)
      if (data) {
        setForbiddenWordsUrl(data.url)
        setForbiddenWordsName(data.display_name)
      } else {
        setForbiddenWordsUrl(null)
        setForbiddenWordsName(null)
      }
    } catch (error: any) {
      if (error.response?.status === 404) {
        setForbiddenWordsUrl(null)
        setForbiddenWordsName(null)
      } else {
        // eslint-disable-next-line no-console
        console.error('Failed to fetch forbidden words:', error)
      }
    }
  }, [])

  // pre-fetch forbidden words as early as possible when the component mounts
  useEffect(() => {
    fetchAndSetForbiddenWords()
  }, [fetchAndSetForbiddenWords])

  // enable the checkbox if a custom forbidden words list exists
  useEffect(() => {
    if (forbiddenWordsUrl && forbiddenWordsName) {
      setCustomForbiddenWordsEnabled(true)
    }
  }, [forbiddenWordsUrl, forbiddenWordsName])

  // focus on the link after forbidden words are updated
  useEffect(() => {
    if (!fileModalOpen && linkRef.current && forbiddenWordsUrl && forbiddenWordsName) {
      linkRef.current.focus()
    }
  }, [fileModalOpen, forbiddenWordsUrl, forbiddenWordsName])

  const deleteForbiddenWords = useCallback(async () => {
    if (commonPasswordsAttachmentId !== null) {
      try {
        await deleteForbiddenWordsFile(commonPasswordsAttachmentId)

        setForbiddenWordsUrl(null)
        setForbiddenWordsName(null)
        setCommonPasswordsAttachmentId(null)

        showFlashAlert({
          message: I18n.t('Forbidden words list deleted successfully.'),
          type: 'success',
        })
      } catch (error) {
        showFlashAlert({
          message: I18n.t('Failed to delete forbidden words list.'),
          type: 'error',
        })
      }
    } else {
      showFlashAlert({
        message: I18n.t('No forbidden words list to delete.'),
        type: 'warning',
      })
    }
  }, [commonPasswordsAttachmentId])

  const handleCancelUploadModal = useCallback(() => {
    setFileModalOpen(false)
  }, [])

  return (
    <>
      <View as="div" margin="medium">
        <Flex alignItems="center" gap="x-small" wrap="wrap">
          <Flex.Item>
            <Checkbox
              checked={customForbiddenWordsEnabled}
              onChange={handleForbiddenWordsToggle}
              label={I18n.t('Customize forbidden words/terms list')}
              data-testid="customForbiddenWordsCheckbox"
            />
          </Flex.Item>
          <Flex.Item>
            (
            <Link
              href="https://github.com/instructure/canvas-lms/blob/master/lib/canvas/security/password_policy.rb#L83"
              target="_blank"
            >
              {I18n.t('see default list here')}
            </Link>
            )
          </Flex.Item>
        </Flex>
        <View
          as="div"
          insetInlineStart="1.75em"
          position="relative"
          margin="xx-small small small 0"
        >
          <Text size="small">
            {I18n.t(
              'Upload a list of forbidden words/terms in addition to the default list. The file should be text file (.txt) with a single word or term per line.'
            )}
          </Text>
          {(!forbiddenWordsUrl || !forbiddenWordsName || !customForbiddenWordsEnabled) && (
            <View as="div" margin="small 0">
              <Button
                disabled={!customForbiddenWordsEnabled}
                renderIcon={IconUploadSolid}
                onClick={() => setFileModalOpen(true)}
                data-testid="uploadButton"
              >
                {I18n.t('Upload')}
              </Button>
            </View>
          )}
        </View>
        {customForbiddenWordsEnabled &&
          forbiddenWordsUrl &&
          forbiddenWordsName &&
          commonPasswordsAttachmentId && (
            <View as="div" margin="0 medium medium medium">
              <Heading level="h4">{I18n.t('Current Custom List')}</Heading>
              <hr />
              <Flex justifyItems="space-between">
                <Flex.Item>
                  <Link
                    href={forbiddenWordsUrl}
                    target="_blank"
                    elementRef={element => {
                      linkRef.current = element as HTMLAnchorElement | null
                    }}
                  >
                    {forbiddenWordsName}
                  </Link>
                </Flex.Item>
                <Flex.Item>
                  <IconButton
                    withBackground={false}
                    withBorder={false}
                    screenReaderLabel="Delete list"
                    onClick={deleteForbiddenWords}
                  >
                    <IconTrashLine color="warning" />
                  </IconButton>
                </Flex.Item>
              </Flex>
              <hr />
            </View>
          )}
      </View>
      <ForbiddenWordsFileUpload
        open={fileModalOpen}
        onDismiss={handleCancelUploadModal}
        onSave={newAttachmentId => {
          setFileModalOpen(false)
          setCommonPasswordsAttachmentId(newAttachmentId)
          setNewlyUploadedAttachmentId(newAttachmentId)
          fetchAndSetForbiddenWords()
        }}
        setForbiddenWordsUrl={setForbiddenWordsUrl}
        setForbiddenWordsFilename={setForbiddenWordsName}
      />
    </>
  )
}

export default CustomForbiddenWordsSection
