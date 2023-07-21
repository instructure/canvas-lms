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

import React, {useState, useEffect, useRef} from 'react'
import {Button} from '@instructure/ui-buttons'
import PropTypes from 'prop-types'
import Modal from '@canvas/instui-bindings/react/InstuiModal'
import {getUserMedia} from '../util/mediaUtils'
import {IconVideoCameraOffSolid} from '@instructure/ui-icons'
import {useScope as useI18nScope} from '@canvas/i18n'
import Focus from '@canvas/outcomes/react/Focus'

const I18n = useI18nScope('webcam_modal')

const WebcamModal = ({onSelectImage, open, onDismiss}) => {
  const videoRef = useRef(null)
  const [takenImage, setTakenImage] = useState({})
  const [permission, setPermission] = useState(null)

  useEffect(() => {
    let stream = null

    if (open) {
      setPermission(null)

      const askingTimeout = setTimeout(() => {
        setPermission('requesting')
      }, 500)

      getUserMedia({video: true})
        .then(strm => {
          stream = strm
          videoRef.current.srcObject = strm
          setPermission('granted')
        })
        .finally(() => {
          clearTimeout(askingTimeout)
        })
        .catch(() => {
          setPermission('not_granted')
        })
    }

    return () => {
      if (stream) {
        stream.getTracks().forEach(track => track.stop())
      }
    }
  }, [open, videoRef])

  const onTakePicture = () => {
    const video = videoRef.current
    const canvas = document.createElement('canvas')
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight
    canvas.getContext('2d').drawImage(video, 0, 0, canvas.width, canvas.height)
    const dataURL = canvas.toDataURL()
    canvas.toBlob(blob => {
      setTakenImage({
        dataURL,
        blob,
      })
    })
  }

  const innerOnSelectImage = () => {
    onSelectImage(takenImage)
    setTakenImage({})
  }

  const showVideo = permission === 'granted' && !takenImage.dataURL

  return (
    <Modal
      open={open}
      onDismiss={() => {
        setTakenImage({})
        onDismiss()
      }}
      size="medium"
      label={I18n.t('Webcam')}
    >
      <Modal.Body>
        {/* eslint-disable jsx-a11y/media-has-caption */}
        <video
          className="webcam-request-video"
          autoPlay={true}
          ref={videoRef}
          style={{display: showVideo ? 'block' : 'none'}}
        />
        {/* eslint-enable jsx-a11y/media-has-caption */}

        {['requesting', 'not_granted'].includes(permission) && (
          <div className="webcam-access-wrapper">
            <div>
              <IconVideoCameraOffSolid size="large" />
              <p>
                <b>{I18n.t('Canvas needs acccess to your camera.')}</b> <br />
                {I18n.t('You can provide this access in your browser settings.')}
              </p>
            </div>
          </div>
        )}
        {takenImage.dataURL && (
          <img src={takenImage.dataURL} style={{width: '100%'}} alt={I18n.t('Captured Image')} />
        )}
      </Modal.Body>
      {permission === 'granted' && (
        <Modal.Footer>
          {!takenImage.dataURL && (
            <Focus>
              <Button color="primary" onClick={onTakePicture}>
                {I18n.t('Take Photo')}
              </Button>
            </Focus>
          )}

          {takenImage.dataURL && (
            <>
              <Button onClick={() => setTakenImage({})} margin="none small">
                {I18n.t('Try Again')}
              </Button>

              <Focus>
                <Button color="primary" onClick={innerOnSelectImage}>
                  {I18n.t('Use This Photo')}
                </Button>
              </Focus>
            </>
          )}
        </Modal.Footer>
      )}
    </Modal>
  )
}

WebcamModal.propTypes = {
  onSelectImage: PropTypes.func.isRequired,
  open: PropTypes.bool.isRequired,
  onDismiss: PropTypes.func.isRequired,
}

export default WebcamModal
