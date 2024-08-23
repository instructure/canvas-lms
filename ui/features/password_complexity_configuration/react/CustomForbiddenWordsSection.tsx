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

import React, {useState, useEffect, useCallback, useRef} from 'react'
import {Checkbox} from '@instructure/ui-checkbox'
import {Heading} from '@instructure/ui-heading'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {IconTrashLine, IconUploadSolid} from '@instructure/ui-icons'
import ForbiddenWordsFileUpload from './ForbiddenWordsFileUpload'
import doFetchApi from '@canvas/do-fetch-api-effect'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'
import {useScope as useI18nScope} from '@canvas/i18n'
import type {GlobalEnv} from '@canvas/global/env/GlobalEnv'

const I18n = useI18nScope('password_complexity_configuration')

declare const ENV: GlobalEnv

interface ForbiddenWordsResponse {
  public_url: string
  filename: string
}

export const fetchLatestForbiddenWords = async (): Promise<ForbiddenWordsResponse | null> => {
  const {response, json} = await doFetchApi({
    path: `/api/v1/accounts/${ENV.ACCOUNT_ID}/password_complexity/latest_forbidden_words`,
    method: 'GET',
  })
  return response.ok ? (json as ForbiddenWordsResponse) ?? null : null
}

// TODO: FOO-4640
const deleteForbiddenWordsFile = async () => {
  try {
    // mocked response as placeholder
    const mockResponse = {
      response: {
        ok: true,
      },
      json: {
        workflow_state: 'deleted',
      },
    }

    // un-comment the real API call when ready to switch from mock to live
    // const response = await doFetchApi({
    //   path: `/api/v1/accounts/${ENV.ACCOUNT_ID}/password_complexity/delete_forbidden_words`,
    //   method: 'PUT',
    //   body: {
    //     workflow_state: 'deleted',
    //   },
    // })

    if (!mockResponse.response.ok) {
      throw new Error('Failed to delete forbidden words file.')
    }

    // return the mock response for now
    return mockResponse

    // un-comment the following line when using the real API call
    // return response
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('Error deleting forbidden words file:', error)
    throw error
  }
}

const CustomForbiddenWordsSection = () => {
  const linkRef = useRef<HTMLAnchorElement | null>(null)
  const [forbiddenWordsUrl, setForbiddenWordsUrl] = useState<string | null>(null)
  const [forbiddenWordsFilename, setForbiddenWordsFilename] = useState<string | null>(null)
  const [fileModalOpen, setFileModalOpen] = useState(false)
  const [customForbiddenWordsEnabled, setCustomForbiddenWordsEnabled] = useState(false)

  const fetchAndSetForbiddenWords = useCallback(async () => {
    try {
      const data = await fetchLatestForbiddenWords()
      if (data) {
        setForbiddenWordsUrl(data.public_url)
        setForbiddenWordsFilename(data.filename)
      } else {
        setForbiddenWordsUrl(null)
        setForbiddenWordsFilename(null)
      }
    } catch (error: any) {
      if (error.response?.status === 404) {
        setForbiddenWordsUrl(null)
        setForbiddenWordsFilename(null)
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
    if (forbiddenWordsUrl && forbiddenWordsFilename) {
      setCustomForbiddenWordsEnabled(true)
    }
  }, [forbiddenWordsUrl, forbiddenWordsFilename])

  // focus on the link after forbidden words are updated
  useEffect(() => {
    if (!fileModalOpen && linkRef.current && forbiddenWordsUrl && forbiddenWordsFilename) {
      linkRef.current.focus()
    }
  }, [fileModalOpen, forbiddenWordsUrl, forbiddenWordsFilename])

  const deleteForbiddenWords = useCallback(async () => {
    try {
      await deleteForbiddenWordsFile()

      setForbiddenWordsUrl(null)
      setForbiddenWordsFilename(null)

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
  }, [])

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
              onChange={() => {
                setCustomForbiddenWordsEnabled(!customForbiddenWordsEnabled)
              }}
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
          {(!forbiddenWordsUrl || !forbiddenWordsFilename || !customForbiddenWordsEnabled) && (
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
        {customForbiddenWordsEnabled && forbiddenWordsUrl && forbiddenWordsFilename && (
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
                  {forbiddenWordsFilename}
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
        onSave={() => {
          setFileModalOpen(false)
          fetchAndSetForbiddenWords()
        }}
        setForbiddenWordsUrl={setForbiddenWordsUrl}
        setForbiddenWordsFilename={setForbiddenWordsFilename}
      />
    </>
  )
}

export default CustomForbiddenWordsSection
