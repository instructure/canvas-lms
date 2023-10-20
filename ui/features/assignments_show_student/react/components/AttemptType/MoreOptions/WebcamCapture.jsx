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
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {func, number} from 'prop-types'
import {useScope as useI18nScope} from '@canvas/i18n'
import {IconRecordSolid, IconVideoCameraOffSolid} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {TextInput} from '@instructure/ui-text-input'
import {View} from '@instructure/ui-view'

const I18n = useI18nScope('webcam_modal')

// Somewhat arbitrary height to allow the video feed to fit comfortably within
// the containing modal
const videoHeight = 456

const Countdown = ({seconds}) => (
  <View className="webcam-countdown-container" data-testid="webcam-countdown-container">
    <Flex as="div" width="100%" height="100%" alignItems="center" justifyItems="center">
      <Flex.Item>{seconds}</Flex.Item>
    </Flex>
  </View>
)

Countdown.propTypes = {
  seconds: number.isRequired,
}

const WebcamAccessRequired = () => (
  <Flex
    as="div"
    direction="column"
    justifyItems="center"
    alignItems="center"
    height={`${videoHeight}px`}
    overflowY="visible"
  >
    <Flex.Item>
      <IconVideoCameraOffSolid size="large" />
    </Flex.Item>
    <Flex.Item>
      <View as="div" textAlign="center">
        <Text weight="bold">{I18n.t('Canvas needs access to your camera.')}</Text>
        <br />
        {I18n.t('You can provide this access in your browser settings.')}
      </View>
    </Flex.Item>
  </Flex>
)

export default function WebcamCapture({onSelectImage}) {
  const videoRef = useRef(null)
  const filenameInputRef = useRef(null)
  const [takenImage, setTakenImage] = useState({})
  const [permission, setPermission] = useState(null)

  const [filename, setFilename] = useState('webcam-picture.png')
  const [countdownTimeMS, setCountdownTimeMS] = useState(null)

  useEffect(() => {
    let stream = null

    const askingTimeout = setTimeout(() => {
      setPermission('requesting')
    }, 500)

    navigator.mediaDevices
      .getUserMedia({video: true})
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

    return () => {
      if (stream) {
        stream.getTracks().forEach(track => track.stop())
      }
    }
  }, [videoRef])

  useEffect(() => {
    if (permission === 'granted' && takenImage.dataURL) {
      const textInput = filenameInputRef.current
      if (textInput && textInput !== document.activeElement) {
        textInput.focus()
        textInput.setSelectionRange(0, textInput.value.lastIndexOf('.png'))
      }
    }
  }, [permission, takenImage])

  useEffect(() => {
    if (countdownTimeMS != null) {
      if (countdownTimeMS > 0) {
        const interval = 1000

        setTimeout(() => {
          setCountdownTimeMS(countdownTimeMS - interval)
        }, interval)
      } else {
        onTakePicture()
        setCountdownTimeMS(null)
      }
    }
  }, [countdownTimeMS])

  const onTakePicture = () => {
    const video = videoRef.current
    const canvas = document.createElement('canvas')
    canvas.width = video.clientWidth
    canvas.height = video.clientHeight
    canvas.getContext('2d').drawImage(video, 0, 0, canvas.width, canvas.height)
    const dataURL = canvas.toDataURL()
    canvas.toBlob(blob => {
      setTakenImage({
        dataURL,
        blob,
      })
    })
  }

  const startCountdown = () => {
    setCountdownTimeMS(3000)
  }

  const handleSaveImage = () => {
    onSelectImage({image: takenImage, filename})
    setTakenImage({})
  }

  const showVideoFeed = permission === 'granted' && takenImage.dataURL == null

  const takePhotoIcon = (
    <IconButton
      alt={I18n.t('Take Photo')}
      color="primary"
      disabled={countdownTimeMS != null}
      margin="0 auto"
      onClick={startCountdown}
      screenReaderLabel={I18n.t('Take Photo')}
      size="large"
      withBackground={false}
      withBorder={false}
    >
      <IconRecordSolid size="medium" />
    </IconButton>
  )

  const savePhotoControls = (
    <Flex width="100%">
      <Flex.Item shouldGrow={true} margin="auto medium auto 0">
        <TextInput
          inputRef={el => {
            filenameInputRef.current = el
          }}
          renderLabel={
            <ScreenReaderContent>{I18n.t('Enter a filename for the photo')}</ScreenReaderContent>
          }
          onChange={(event, value) => {
            setFilename(value)
          }}
          value={filename}
        />
      </Flex.Item>

      <Flex.Item margin="auto 0 auto medium">
        <Button color="primary" onClick={handleSaveImage}>
          {I18n.t('Save')}
        </Button>
      </Flex.Item>

      <Flex.Item>
        <Button onClick={() => setTakenImage({})} margin="none small">
          {I18n.t('Start Over')}
        </Button>
      </Flex.Item>
    </Flex>
  )

  return (
    <View as="div" position="relative">
      <Flex direction="column" justifyItems="center">
        <Flex.Item as="div" size={`${videoHeight}px`}>
          {/* eslint-disable jsx-a11y/media-has-caption */}
          <video
            autoPlay={true}
            data-testid="webcam-capture-video"
            height={videoHeight}
            ref={videoRef}
            style={{display: showVideoFeed ? 'block' : 'none', margin: '0 auto'}}
          />
          {/* eslint-enable jsx-a11y/media-has-caption */}

          {countdownTimeMS != null && countdownTimeMS > 0 && (
            <Countdown seconds={Math.ceil(countdownTimeMS / 1000)} />
          )}

          {['requesting', 'not_granted'].includes(permission) && <WebcamAccessRequired />}

          {takenImage.dataURL && (
            <Img
              alt={I18n.t('Captured Image')}
              display="block"
              height={`${videoHeight}px`}
              margin="0 auto"
              src={takenImage.dataURL}
            />
          )}
        </Flex.Item>
        {permission === 'granted' && (
          <Flex.Item margin="x-small" overflowY="visible" textAlign="center">
            {takenImage.dataURL != null ? savePhotoControls : takePhotoIcon}
          </Flex.Item>
        )}
      </Flex>
    </View>
  )
}

WebcamCapture.propTypes = {
  onSelectImage: func.isRequired,
}
