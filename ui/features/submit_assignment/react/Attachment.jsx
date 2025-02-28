/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import React, {useEffect, useRef, useState} from 'react'
import Focus from '@canvas/outcomes/react/Focus'
import PropTypes, {arrayOf} from 'prop-types'
import UploadFileSVG from '../images/UploadFile.svg'
import WebcamModal from './WebcamModal'
import {AccessibleContent, ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {direction} from '@canvas/i18n/rtlHelper'
import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import {hasMediaFeature} from '../util/mediaUtils'
import {IconImageLine, IconTrashLine, IconWarningSolid} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('attachment')

const Attachment = ({
  index,
  setBlob,
  validFileTypes,
  getShouldShowFileRequiredError,
  setShouldShowFileRequiredError
}) => {
  const [openWebcamModal, setOpenWebcamModal] = useState(false)
  const [dataURL, setDataURL] = useState(null)
  const [file, setFile] = useState(null)
  const [errorMessages, setErrorMessages] = useState([])

  const useWebcamRef = useRef(null)
  const fileInputPlaceholderRef = useRef(null)

  // TODO: When we upgrade to InstUI 10, the inputRef prop will be available to use.
  // For now, we query for the input by its id
  const getFileDropInput = () => document.getElementById(`submission_file_drop_${index}`)

  const formatErrorMessage = (message) => (
    <Text size="small" color="danger">
      <View margin="0 xx-small 0 0">
        <IconWarningSolid color="error" />
      </View>
      {message}
    </Text>
  )

  useEffect(() => {
    const handleFocus = () => {
      if (getShouldShowFileRequiredError()) {
        const errorText = formatErrorMessage(I18n.t('A file is required to make a submission.'))
        setErrorMessages([{ text: errorText, type: 'error' }])
        // reset the value
        setShouldShowFileRequiredError(false)
      }
    }
    const fileDropInput = getFileDropInput()
    if (fileDropInput) {
      // set these values from the legacy input on the FileDrop's input
      fileDropInput.name = `attachments[${index}][uploaded_data]`
      fileDropInput.className = `${fileDropInput.className} input-file`
      fileDropInput.setAttribute("data-testid", `file-upload-${index}`)
      // set up focus listener
      fileDropInput.addEventListener("focus", handleFocus)
    }

    return () => {
      if (fileDropInput) fileDropInput.removeEventListener("focus", handleFocus)
    }
  }, [file])

  useEffect(() => {
    return () => {
      setBlob(null)
    }
  }, [setBlob])

  const clearErrors = () => {
    setShouldShowFileRequiredError(false)
    setErrorMessages([])
  }

  const clearInputFile = () => {
    getFileDropInput().value = ''
    fileInputPlaceholderRef.current?.replaceChildren()
    setFile(null)
  }

  const handleAcceptFile = (file) => {
    if (file.size === 0) {
      const errorText = formatErrorMessage(I18n.t('Attached files must be greater than 0 bytes.'))
      setErrorMessages([{ text: errorText, type: 'error' }])
      // Clear the file from the input since we are not accepting it
      clearInputFile()
    } else {
      // We want the input element from the FileDrop component to persist
      const fileDropInput = getFileDropInput()
      if (fileDropInput && fileInputPlaceholderRef.current) {
        fileInputPlaceholderRef.current.appendChild(fileDropInput)
      }
      setFile(file)
    }
  }

  const handleRejectedFile = (_file) => {
    const fileTypes = validFileTypes.join(", ")
    const errorText = formatErrorMessage(I18n.t('This file type is not allowed. Accepted file types are: %{fileTypes}.', {fileTypes}))
    setErrorMessages([{ text: errorText, type: 'error' }])
  }

  const useWebcamButton = (
    <Button
      renderIcon={IconImageLine}
      onClick={() => setOpenWebcamModal(true)}
      margin="none small"
      ref={useWebcamRef}
      id={`webcam_button_${index}`}
    >
      {I18n.t('Use Webcam')}
    </Button>
  )

  const legacyFileUpload = (index) => {
    return (
      <>
        {!file && (
          <Flex direction='column'>
            <Flex width='100%'>
              <FileDrop
                id={`submission_file_drop_${index}`}
                accept={validFileTypes.length > 0 ? validFileTypes : undefined}
                onClick={clearErrors}
                onDrop={clearErrors}
                onDropAccepted={([file]) => handleAcceptFile(file)}
                onDropRejected={([file]) => handleRejectedFile(file)}
                messages={errorMessages}
                renderLabel={
                  <View
                    as="div"
                    padding="small"
                    margin="medium small"
                    textAlign="center"
                    background="primary"
                  >
                    <View as="div" margin="x-large">
                      <Img src={UploadFileSVG} height='172px' />
                    </View>
                    <View as="div">
                      <Text size="large" lineHeight="double">
                        {I18n.t('Drag a file here, or')}
                      </Text>
                    </View>
                    <View as="div">
                      <Text size="medium" color="brand" lineHeight="double">
                        {I18n.t('Choose a file to upload')}
                      </Text>
                    </View>
                  </View>
                }
                display='inline-block'
                width='25rem'
                margin='x-small'
                data-testid={`submission_file_drop_${index}`}
              />
            </Flex>
            {(hasMediaFeature() && (validFileTypes.length === 0 || validFileTypes.includes('png')) && !dataURL) && (
              <Flex width='100%' margin='small 0'>
                {useWebcamButton}
              </Flex>
            )}
          </Flex>
        )}
        <div ref={fileInputPlaceholderRef}></div>
        {file && (
          <Tag
            id={`submission_file_tag_${index}`}
            text={<AccessibleContent alt={file.name}>{file.name}</AccessibleContent>}
            dismissible={true}
            onClick={clearInputFile}
            data-testid={`submission_file_tag_${index}`}
          />
        )}
      </>
    )
  }

  if (!hasMediaFeature()) {
    return legacyFileUpload(index)
  }

  return (
    <>
      {dataURL ? (
        <div className="preview-webcam-image-wrapper" style={{position: 'relative'}}>
          <img
            src={dataURL}
            alt={I18n.t('Captured Image')}
            style={{width: '13em', height: '10em'}}
          />

          <span
            style={{
              position: 'absolute',
              top: '0.4em',
              [direction('right')]: '0.4em',
            }}
          >
            <Focus timeout={500}>
              <Button
                renderIcon={IconTrashLine}
                size="small"
                color="primary-inverse"
                data-testid="removePhotoButton"
                onClick={() => {
                  setDataURL(null)
                  setBlob(null)

                  setTimeout(() => {
                    useWebcamRef.current.focus()
                  }, 100)
                }}
              >
                <ScreenReaderContent>
                  {I18n.t('Remove webcam image %{count}', {count: index + 1})}
                </ScreenReaderContent>
              </Button>
            </Focus>
          </span>
        </div>
      ) : (legacyFileUpload(index))}

      <WebcamModal
        open={openWebcamModal}
        onDismiss={() => setOpenWebcamModal(false)}
        onSelectImage={params => {
          setBlob(params.blob)
          setDataURL(params.dataURL)
          setOpenWebcamModal(false)
          clearErrors()
        }}
      />
    </>
  )
}

Attachment.propTypes = {
  index: PropTypes.number.isRequired,
  setBlob: PropTypes.func.isRequired,
  validFileTypes: arrayOf(PropTypes.string),
  getShouldShowFileRequiredError: PropTypes.func,
  setShouldShowFileRequiredError: PropTypes.func
}

Attachment.defaultProps = {
  validFileTypes: [],
  getShouldShowFileRequiredError: () => {},
  setShouldShowFileRequiredError: () => {}
}

export default Attachment
