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

import React, {useEffect, useRef, useState, useCallback} from 'react'
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
import {IconImageLine, IconTrashLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Tag} from '@instructure/ui-tag'
import {Text} from '@instructure/ui-text'
import {useScope as createI18nScope} from '@canvas/i18n'
import {View} from '@instructure/ui-view'

const I18n = createI18nScope('attachment')

const Attachment = ({
  index,
  setBlob,
  validFileTypes = [],
  getShouldShowFileRequiredError = () => {},
  setShouldShowFileRequiredError = () => {},
}) => {
  const [openWebcamModal, setOpenWebcamModal] = useState(false)
  const [dataURL, setDataURL] = useState(null)
  const [file, setFile] = useState(null)
  const [errorMessages, setErrorMessages] = useState([])

  const useWebcamRef = useRef(null)
  const fileInputPlaceholderRef = useRef(null)

  const fileTypeError = () => {
    const fileTypes = validFileTypes.join(', ')
    return I18n.t('This file type is not allowed. Accepted file types are: %{fileTypes}.', {
      fileTypes,
    })
  }

  // TODO: When we upgrade to InstUI 10, the inputRef prop will be available to use.
  // For now, we query for the input by its id
  const getFileDropInput = () => document.getElementById(`submission_file_drop_${index}`)

  useEffect(() => {
    const handleFocus = () => {
      if (getShouldShowFileRequiredError()) {
        const errorText = I18n.t('A file is required to make a submission.')
        setErrorMessages([{text: errorText, type: 'newError'}])
        // reset the value
        setShouldShowFileRequiredError(false)
      }
    }
    // There is a case where the user drags and drops a file while the native file browser
    // is open. When this is the case, we can't rely on handleAcceptFile to update the
    // state and need to observe changes on the input.
    const handleChange = e => {
      const files = e.target.files
      const fileDropInput = getFileDropInput()
      if (file && files.length === 0 && fileDropInput) {
        // If the user clicks "Cancel", the input will be cleared and we should update the UI to reflect that.
        clearInputFile()
      } else if (files.length > 0 && fileDropInput) {
        persistFileInput(fileDropInput)
        // If the user clicks "Open", the input will be updated and we should update the UI to reflect that.
        const newFile = files[0]
        if (newFile !== file && isValidFileType(newFile) && isValidFileSize(newFile)) {
          setFile(newFile)
        }
      }
    }
    const fileDropInput = getFileDropInput()
    if (fileDropInput) {
      // set these values from the legacy input on the FileDrop's input
      fileDropInput.name = `attachments[${index}][uploaded_data]`
      fileDropInput.className = `${fileDropInput.className} input-file`
      fileDropInput.setAttribute('data-testid', `file-upload-${index}`)
      // set up focus listener
      fileDropInput.addEventListener('focus', handleFocus)
      fileDropInput.addEventListener('change', handleChange)
    }

    return () => {
      if (fileDropInput) {
        fileDropInput.removeEventListener('focus', handleFocus)
        fileDropInput.removeEventListener('change', handleChange)
      }
    }
  }, [file])

  useEffect(() => {
    return () => {
      setBlob(null)
    }
  }, [setBlob])

  const persistFileInput = useCallback(fileDropInput => {
    fileInputPlaceholderRef.current?.appendChild(fileDropInput)
  }, [])

  const clearErrors = () => {
    setShouldShowFileRequiredError(false)
    setErrorMessages([])
  }

  const clearInputFile = () => {
    getFileDropInput().value = ''
    fileInputPlaceholderRef.current?.replaceChildren()
    setFile(null)
  }

  const getFileExtension = file => {
    const name = file.name
    const match = name.match(/\.([^.]+)$/)
    return match ? match[1] : ''
  }

  const isValidFileType = file => {
    const type = getFileExtension(file)
    if (!validFileTypes.includes(type)) {
      setErrorMessages([{text: fileTypeError(), type: 'newError'}])
      return false
    }
    return true
  }

  const isValidFileSize = file => {
    if (file.size === 0) {
      const errorText = I18n.t('Attached files must be greater than 0 bytes.')
      setErrorMessages([{text: errorText, type: 'newError'}])
      // Clear the file from the input since we are not accepting it
      clearInputFile()
      return false
    }
    return true
  }

  const handleAcceptFile = ([file], e) => {
    if (isValidFileSize(file)) {
      // We want the input element from the FileDrop component to persist
      const fileDropInput = getFileDropInput()
      // With drag and drop, the value of the input is not updated. We need to
      // use the datatransfer from the event to set the value of the input to the dropped file
      if (!fileDropInput.value) {
        fileDropInput.files = e.dataTransfer?.files
      }
      if (fileDropInput) {
        persistFileInput(fileDropInput)
      }
      setFile(file)
    }
  }

  const handleRejectedFile = _file => {
    setErrorMessages([{text: fileTypeError(), type: 'newError'}])
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

  const legacyFileUpload = index => {
    return (
      <>
        {!file && (
          <Flex direction="column">
            <Flex width="100%">
              <FileDrop
                id={`submission_file_drop_${index}`}
                accept={validFileTypes.length > 0 ? validFileTypes : undefined}
                onClick={clearErrors}
                onDrop={clearErrors}
                onDropAccepted={handleAcceptFile}
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
                      <Img src={UploadFileSVG} height="172px" />
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
                display="inline-block"
                width="25rem"
                margin="x-small"
                data-testid={`submission_file_drop_${index}`}
              />
            </Flex>
            {hasMediaFeature() &&
              (validFileTypes.length === 0 || validFileTypes.includes('png')) &&
              !dataURL && (
                <Flex width="100%" margin="small 0">
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
      ) : (
        legacyFileUpload(index)
      )}

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
  setShouldShowFileRequiredError: PropTypes.func,
}

export default Attachment
