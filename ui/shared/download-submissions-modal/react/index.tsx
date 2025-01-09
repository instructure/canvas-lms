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

import React, {useEffect, useState} from 'react'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {IconCheckMarkLine} from '@instructure/ui-icons'
import {Modal} from '@instructure/ui-modal'
import {ProgressBar} from '@instructure/ui-progress'
import {Text} from '@instructure/ui-text'
import {View} from '@instructure/ui-view'
import useBoolean from '@canvas/outcomes/react/hooks/useBoolean'
import doFetchApi, {type DoFetchApiResults} from '@canvas/do-fetch-api-effect'
import {useScope as createI18nScope} from '@canvas/i18n'
import WithBreakpoints, {type Breakpoints} from '@canvas/with-breakpoints'

const I18n = createI18nScope('download_submissions_modal')

const DownloadSubmissionsModal = ({
  open,
  handleCloseModal,
  assignmentId,
  courseId,
  breakpoints,
}: {
  open: boolean
  handleCloseModal: void
  assignmentId: string
  courseId: string
  breakpoints: Breakpoints
}): React.ReactElement => {
  const [downloadProgress, setDownloadProgress] = useState(0)
  const [fileSize, setFileSize] = useState(null)
  const [error, setErrorTrue, setErrorFalse] = useBoolean(false)

  useEffect(() => {
    if (open && !fileSize) {
      ;(() => {
        // @ts-expect-error
        setErrorFalse()
        setDownloadProgress(1)
        doFetchApi({
          path: `/courses/${courseId}/assignments/${assignmentId}/submissions?zip=1`,
          method: 'GET',
        })
          .then((response: DoFetchApiResults<any>) => {
            setFileSize(response?.json?.attachment?.size)
            setDownloadProgress(100)
          })
          .catch((_err: Error) => {
            // @ts-expect-error
            setErrorTrue()
          })
      })()
    }
  }, [assignmentId, courseId, fileSize, open, setErrorFalse, setErrorTrue])

  useEffect(() => {
    if (fileSize) {
      const download = document.getElementById('download_button')
      download?.click()
    }
  }, [fileSize])

  useEffect(() => {
    if (downloadProgress < 90 && !fileSize) {
      const incrementProgressValue = () =>
        setDownloadProgress((prevValue: number) =>
          prevValue < 100 && !error ? prevValue + 1 : prevValue,
        )
      setTimeout(() => {
        incrementProgressValue()
      }, 50)
    }
  }, [downloadProgress, error, fileSize])

  const renderProgressValue = ({valueNow}: {valueNow: number}): React.ReactElement => {
    return (
      <Flex justifyItems="end" padding="0 xx-small 0 0">
        <Text weight="bold" size="large" data-testid="progress-value">
          {I18n.t('%{percent}%', {percent: valueNow})}
        </Text>
      </Flex>
    )
  }

  const renderProgressText = () => {
    let text = I18n.t('In Progress.')
    if (error) {
      text = I18n.t('Failed to gather and compress files.')
    } else if (fileSize) {
      text = I18n.t('Finished preparing %{size_of_file} Bytes.', {size_of_file: fileSize})
    }
    return (
      <>
        {fileSize && (
          <View margin="0 xx-small 0 0">
            <IconCheckMarkLine />
          </View>
        )}
        <Text color={error ? 'danger' : 'primary'} data-testid="progress-text">
          {text}
        </Text>
      </>
    )
  }

  return (
    <Modal
      open={open}
      size={breakpoints.mobileOnly ? 'fullscreen' : 'small'}
      label={I18n.t('Download Submissions')}
    >
      <Modal.Header>
        <CloseButton
          placement="end"
          offset="small"
          // @ts-expect-error
          onClick={handleCloseModal}
          screenReaderLabel={I18n.t('Close')}
        />
        <Heading>{I18n.t('Download Submissions')}</Heading>
      </Modal.Header>
      <Modal.Body>
        <Text>
          {I18n.t(
            'Your student submissions are being gathered and compressed into a zip file. This may take some time depending on the size and number of submission files.',
          )}
        </Text>
        <View as="div" margin="medium 0" borderWidth={error ? 'small' : '0'} borderColor="danger">
          <ProgressBar
            size="large"
            screenReaderLabel={I18n.t('Download Submissions Progress Bar')}
            valueNow={downloadProgress}
            valueMax={100}
            meterColor="info"
            renderValue={renderProgressValue}
            themeOverride={{
              trackBottomBorderWidth: '0',
            }}
          />
        </View>
        {renderProgressText()}
      </Modal.Body>
      <Modal.Footer>
        {/* @ts-expect-error */}
        <Button onClick={handleCloseModal} margin="0 x-small 0 0">
          {I18n.t('Cancel')}
        </Button>
        <Button
          id="download_button"
          data-testid="download_button"
          href={`/courses/${courseId}/assignments/${assignmentId}/submissions?zip=1`}
          color="primary"
          interaction={fileSize ? 'enabled' : 'disabled'}
        >
          {I18n.t('Download')}
        </Button>
      </Modal.Footer>
    </Modal>
  )
}

export default WithBreakpoints(DownloadSubmissionsModal)
