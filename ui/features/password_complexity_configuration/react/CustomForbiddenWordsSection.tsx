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
import {useScope as createI18nScope} from '@canvas/i18n'
import {deleteForbiddenWordsFile} from './apiClient'
import {executeApiRequest} from '@canvas/do-fetch-api-effect/apiRequest'

const I18n = createI18nScope('password_complexity_configuration')

interface Props {
  currentAttachmentId: number | null
  passwordPolicyHashExists: boolean
  setNewlyUploadedAttachmentId: (attachmentId: number | null) => void
  onCustomForbiddenWordsEnabledChange: (enabled: boolean) => void
  setCurrentAttachmentId: (attachmentId: number | null) => void
  setEnableApplyButton: (enabled: boolean) => void
}

interface ForbiddenWordsResponse {
  url: string
  display_name: string
}

export const fetchLatestForbiddenWords = async (
  attachmentId: number,
): Promise<ForbiddenWordsResponse | null> => {
  const {status, data} = await executeApiRequest<ForbiddenWordsResponse>({
    path: `/api/v1/files/${attachmentId}`,
    method: 'GET',
  })
  return status === 200 ? (data ?? null) : null
}

const CustomForbiddenWordsSection = ({
  setNewlyUploadedAttachmentId,
  onCustomForbiddenWordsEnabledChange,
  currentAttachmentId,
  passwordPolicyHashExists,
  setCurrentAttachmentId,
  setEnableApplyButton,
}: Props) => {
  const linkRef = useRef<HTMLAnchorElement | null>(null)
  const [forbiddenWordsUrl, setForbiddenWordsUrl] = useState<string | null>(null)
  const [forbiddenWordsName, setForbiddenWordsName] = useState<string | null>(null)
  const [fileModalOpen, setFileModalOpen] = useState(false)
  const [customForbiddenWordsEnabled, setCustomForbiddenWordsEnabled] = useState(false)
  const [commonPasswordsAttachmentId, setCommonPasswordsAttachmentId] = useState<number | null>(
    null,
  )
  const [forbiddenWordsFileEnabled, setForbiddenWordsEnabled] = useState(false)

  const handleForbiddenWordsToggle = () => {
    const newEnabledState = !customForbiddenWordsEnabled
    setCustomForbiddenWordsEnabled(newEnabledState)
    onCustomForbiddenWordsEnabledChange(newEnabledState)
  }

  const fetchAndSetForbiddenWords = useCallback(async () => {
    if (passwordPolicyHashExists) {
      setForbiddenWordsEnabled(true)
    }

    if (currentAttachmentId && currentAttachmentId !== commonPasswordsAttachmentId) {
      setCommonPasswordsAttachmentId(currentAttachmentId)
      try {
        const data = await fetchLatestForbiddenWords(currentAttachmentId)
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
          showFlashAlert({
            message: I18n.t('Failed to fetch latest forbidden words.'),
            type: 'error',
          })
        }
      }
    }
  }, [currentAttachmentId, passwordPolicyHashExists, commonPasswordsAttachmentId])

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

        setCurrentAttachmentId(null)
        setForbiddenWordsUrl(null)
        setForbiddenWordsName(null)
        setCommonPasswordsAttachmentId(null)
        setEnableApplyButton(true)

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
  }, [commonPasswordsAttachmentId, setCurrentAttachmentId, setEnableApplyButton])

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
              disabled={!forbiddenWordsFileEnabled}
            />
          </Flex.Item>
          <Flex.Item>
            (
            <Link
              href="https://github.com/instructure/canvas-lms/blob/master/lib/canvas/security/password_policy.rb#:~:text=DEFAULT_COMMON_PASSWORDS%20%3D%20%25w%5B"
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
              'Upload a list of forbidden words/terms in addition to the default list. The file should be text file (.txt) with a single word or term per line.',
            )}
          </Text>
          {(!forbiddenWordsUrl || !forbiddenWordsName || !customForbiddenWordsEnabled) && (
            <View as="div" margin="small 0">
              <Button
                disabled={!customForbiddenWordsEnabled}
                // @ts-expect-error
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
        setCurrentAttachmentId={setCurrentAttachmentId}
        setCommonPasswordsAttachmentId={setCommonPasswordsAttachmentId}
        setEnableApplyButton={setEnableApplyButton}
      />
    </>
  )
}

export default CustomForbiddenWordsSection
