/*
 * Copyright (C) 2025 - present Instructure, Inc.
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
import CanvasSelect from '@canvas/instui-bindings/react/Select'
import {Button, CloseButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {Heading} from '@instructure/ui-heading'
import {Modal} from '@instructure/ui-modal'
import {useEffect, useRef, useState} from 'react'
import TakePictureView from '../backbone/views/TakePictureView'
import UploadFileView from '../backbone/views/UploadFileView'
import GravatarView from '../backbone/views/GravatarView'
import {GlobalEnv} from '@canvas/global/env/GlobalEnv'
import {handleUpdatingProfilePicture, updateAvatarInDom, getImage, preflightRequest} from './util'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import {Spinner} from '@instructure/ui-spinner'
import {View} from '@instructure/ui-view'

declare const ENV: GlobalEnv & {enable_gravatar: boolean}

const I18n = createI18nScope('profile')

const takePicture = 'camera-option'
const uploadPicture = 'upload-option'
const fromGravatar = 'gravatar-option'

const AVATAR_SIZE = {h: 128, w: 128}

interface Props {
  onClose: () => void
}

type ExtendedNavigator = Navigator & {
  getUserMedia: any
  mozGetUserMedia: any
  msGetUserMedia: any
  webkitGetUserMedia: any
}

export default function AvatarModal(props: Props) {
  const [loading, setLoading] = useState(false)
  const [imageType, setImageType] = useState<string | null>(null)
  const [fileOptions, setFileOptions] = useState<JSX.Element[]>()
  const cameraView = useRef<TakePictureView | null>(null)
  const uploadView = useRef<UploadFileView | null>(null)
  const gravatarView = useRef<GravatarView | null>(null)

  useEffect(() => {
    // adds each Select option + default image type
    let defaultImageType = null
    const selectOptions = []
    const {hasFileReader, enableGravatar, hasUserMedia} = findAvatarOptions()
    if (enableGravatar) {
      selectOptions.push(
        <CanvasSelect.Option key={fromGravatar} id={fromGravatar} value={fromGravatar}>
          {I18n.t('From Gravatar')}
        </CanvasSelect.Option>,
      )
      defaultImageType = fromGravatar
    }

    if (hasUserMedia) {
      selectOptions.push(
        <CanvasSelect.Option key={takePicture} id={takePicture} value={takePicture}>
          {I18n.t('Take a Picture')}
        </CanvasSelect.Option>,
      )
      defaultImageType = takePicture
    }

    if (hasFileReader) {
      selectOptions.push(
        <CanvasSelect.Option key={uploadPicture} id={uploadPicture} value={uploadPicture}>
          {I18n.t('Upload a Picture')}
        </CanvasSelect.Option>,
      )
      defaultImageType = uploadPicture
    }

    setFileOptions(selectOptions.reverse())
    setImageType(defaultImageType)

    return () => {
      cameraView.current?.teardown()
      uploadView.current?.teardown()
      gravatarView.current?.teardown()
    }
  }, [])

  const setCameraPane = (node: HTMLDivElement | null) => {
    if (node && cameraView.current === null) {
      cameraView.current = new TakePictureView({
        el: node,
        avatarSize: AVATAR_SIZE,
      })
      cameraView.current.render()
    }
  }

  const setGravatarPane = (node: HTMLDivElement | null) => {
    if (node && gravatarView.current === null) {
      gravatarView.current = new GravatarView({el: node, avatarSize: AVATAR_SIZE})
      gravatarView.current.render()
      gravatarView.current.setup()
    }
  }

  const setUploadPane = (node: HTMLDivElement | null) => {
    if (node && uploadView.current === null) {
      uploadView.current = new UploadFileView({el: node, avatarSize: AVATAR_SIZE})
      uploadView.current.render()
    }
  }

  const findAvatarOptions = () => {
    const hasFileReader = !!window.FileReader
    const navigatorWithTyping = navigator as ExtendedNavigator
    const hasUserMedia = !!(
      (navigatorWithTyping.mediaDevices &&
        navigatorWithTyping.mediaDevices?.getUserMedia({video: true})) ||
      navigatorWithTyping.getUserMedia ||
      navigatorWithTyping.mozGetUserMedia ||
      navigatorWithTyping.msGetUserMedia ||
      navigatorWithTyping.webkitGetUserMedia
    )
    const enableGravatar = ENV.enable_gravatar
    return {enableGravatar, hasFileReader, hasUserMedia}
  }

  const handleError = (error: Error) => {
    showFlashError(I18n.t('Failed to update avatar'))(error)
  }

  const onSubmit = async () => {
    setLoading(true)
    if (imageType === fromGravatar) {
      try {
        const gravatarUrl = await gravatarView.current?.updateAvatar()
        setImageType(null)
        updateAvatarInDom(gravatarUrl)
        props.onClose()
      } catch (error) {
        handleError(error as Error)
      } finally {
        setImageType(fromGravatar)
      }
    } else if (imageType === uploadPicture) {
      try {
        const setupResponses = await Promise.all([getImage(uploadView.current), preflightRequest()])
        setImageType(null)
        await handleUpdatingProfilePicture(setupResponses)
        props.onClose()
      } catch (error) {
        handleError(error as Error)
      } finally {
        setImageType(uploadPicture)
      }
    } else if (imageType === takePicture) {
      try {
        const setupResponses = await Promise.all([getImage(cameraView.current), preflightRequest()])
        setImageType(null)
        await handleUpdatingProfilePicture(setupResponses)
        props.onClose()
      } catch (error) {
        handleError(error as Error)
      } finally {
        setImageType(takePicture)
      }
    }
    setLoading(false)
  }

  const onChangeImageType = (updatedType: string) => {
    if (cameraView.current && updatedType === takePicture) {
      cameraView.current.setup()
    }
    setImageType(updatedType)
  }

  const renderModalBody = () => {
    return (
      <Flex gap="inputFields" direction="column" id="avatar-modal-body">
        {loading && imageType === null ? (
          <View margin="auto" textAlign="center" as="div" width="100%" height="100%">
            <Spinner size="medium" renderTitle={I18n.t('Updating avatar')} />
          </View>
        ) : (
          <CanvasSelect
            data-testid="avatar-type-select"
            label={I18n.t('Picture Options')}
            id="avatar-type-select"
            onChange={(_e, value) => onChangeImageType(value)}
            value={imageType ? imageType : ''}
          >
            {fileOptions}
          </CanvasSelect>
        )}
        <div
          data-testid="camera-panel"
          style={{display: imageType === takePicture ? 'block' : 'none'}}
          ref={ref => setCameraPane(ref)}
          className="text-center"
        ></div>
        <div
          data-testid="upload-panel"
          style={{display: imageType === uploadPicture ? 'block' : 'none'}}
          ref={ref => setUploadPane(ref)}
          className="text-center"
        ></div>
        <div
          data-testid="gravatar-panel"
          style={{display: imageType === fromGravatar ? 'block' : 'none'}}
          ref={ref => setGravatarPane(ref)}
          className="text-center"
        ></div>
      </Flex>
    )
  }

  return (
    <Modal
      label={I18n.t('Select Profile Picture')}
      open={true}
      onDismiss={props.onClose}
      size="medium"
      data-testid="avatar-modal"
      shouldCloseOnDocumentClick={false}
    >
      <Modal.Header>
        <Heading>{I18n.t('Select Profile Picture')}</Heading>
        <CloseButton
          data-testid="close-modal-button"
          onClick={props.onClose}
          screenReaderLabel={I18n.t('Close')}
          placement="end"
        />
      </Modal.Header>
      <Modal.Body>{renderModalBody()}</Modal.Body>
      <Modal.Footer>
        <Flex gap="buttons">
          <Button
            data-testid="save-avatar-button"
            onClick={() => {
              onSubmit()
            }}
            color="primary"
            disabled={loading}
          >
            {I18n.t('Save')}
          </Button>
          <Button onClick={props.onClose} disabled={loading} data-testid="cancel-avatar-button">
            {I18n.t('Cancel')}
          </Button>
        </Flex>
      </Modal.Footer>
    </Modal>
  )
}
