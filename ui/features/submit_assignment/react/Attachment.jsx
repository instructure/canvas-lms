// Copyright (C) 2021 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {IconImageLine, IconTrashLine, IconUploadLine} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import React, {useEffect, useRef, useState} from 'react'
import WebcamModal from './WebcamModal'
import {hasMediaFeature} from '../util/mediaUtils'
import {useScope as useI18nScope} from '@canvas/i18n'
import {direction} from '@canvas/i18n/rtlHelper'
import Focus from '@canvas/outcomes/react/Focus'

const I18n = useI18nScope('attachment')

const LegacyFileUpload = ({index}) => {
  return (
    <label htmlFor={`attachments[${index}][uploaded_data]`}>
      <ScreenReaderContent>{I18n.t('Upload a file')}</ScreenReaderContent>
      <input
        type="file"
        name={`attachments[${index}][uploaded_data]`}
        className="input-file"
        data-testid={`file-upload-${index}`}
      />
    </label>
  )
}

LegacyFileUpload.propTypes = {
  index: PropTypes.number.isRequired,
}

const Attachment = ({index, setBlob}) => {
  const [openWebcamModal, setOpenWebcamModal] = useState(false)
  const [showFileInput, setShowFileInput] = useState(false)
  const [dataURL, setDataURL] = useState(null)
  const useWebcamRef = useRef(null)

  useEffect(() => {
    return () => {
      setBlob(null)
    }
  }, [setBlob])

  if (!hasMediaFeature()) {
    return <LegacyFileUpload index={index} />
  }

  return (
    <>
      {!dataURL && !showFileInput && (
        <>
          <Button renderIcon={IconUploadLine} onClick={() => setShowFileInput(true)}>
            {I18n.t('Upload File')}
          </Button>

          <Button
            renderIcon={IconImageLine}
            onClick={() => setOpenWebcamModal(true)}
            margin="none small"
            ref={useWebcamRef}
          >
            {I18n.t('Use Webcam')}
          </Button>
        </>
      )}

      {showFileInput && <LegacyFileUpload index={index} />}

      {dataURL && (
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
      )}

      <WebcamModal
        open={openWebcamModal}
        onDismiss={() => setOpenWebcamModal(false)}
        onSelectImage={params => {
          setBlob(params.blob)
          setDataURL(params.dataURL)
          setOpenWebcamModal(false)
        }}
      />
    </>
  )
}

Attachment.propTypes = {
  index: PropTypes.number.isRequired,
  setBlob: PropTypes.func.isRequired,
}

Attachment.defaultProps = {}

export default Attachment
