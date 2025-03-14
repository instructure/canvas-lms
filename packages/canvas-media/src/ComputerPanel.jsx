/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import React, {
  forwardRef,
  Suspense,
  useCallback,
  useEffect,
  useImperativeHandle,
  useRef,
  useState
} from 'react'
import {
  arrayOf,
  bool,
  func,
  instanceOf,
  number,
  oneOfType,
  shape,
  string,
  element,
} from 'prop-types'

import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import {Checkbox} from '@instructure/ui-checkbox'
import {FileDrop} from '@instructure/ui-file-drop'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {IconTrashLine, IconVideoLine, IconWarningSolid} from '@instructure/ui-icons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Text} from '@instructure/ui-text'
import {px} from '@instructure/ui-utils'
import {MediaPlayer} from '@instructure/ui-media-player'
import {StudioPlayer} from '@instructure/studio-player'
import {TextInput} from '@instructure/ui-text-input'
import {Spinner} from '@instructure/ui-spinner'
import formatMessage from './format-message'

import RocketSVG from './RocketSVG'
import translationShape from './translationShape'
import useComputerPanelFocus from './useComputerPanelFocus'
import {isAudio, isVideo, isPreviewable, sizeMediaPlayer} from './shared/utils'

const ClosedCaptionPanel = React.lazy(() => import('./ClosedCaptionCreator'))

const ComputerPanel = forwardRef(({
  accept,
  hasUploadedFile,
  label,
  liveRegion,
  setFile,
  setHasUploadedFile,
  theFile,
  uploadMediaTranslations,
  updateSubtitles,
  userLocale,
  bounds,
  mountNode,
  useStudioPlayer,
}, ref) => {
  const {
    ADD_CLOSED_CAPTIONS_OR_SUBTITLES,
    CHOOSE_FILE_TO_UPLOAD,
    CLEAR_FILE_TEXT,
    DRAG_DROP_CLICK_TO_BROWSE,
    ENTER_FILE_NAME,
    SELECT_SUPPORTED_FILE_TYPE
  } = uploadMediaTranslations.UploadMediaStrings
  const [fileDropMessages, setFileDropMessages] = useState([])
  const [fileNameMessages, setFileNameMessages] = useState([])
  const [mediaTracksCheckbox, setMediaTracksCheckbox] = useState(false)
  const [previewURL, setPreviewURL] = useState(null)
  const height = useStudioPlayer
    ? 400
    : 0.8 * (bounds?.height - 38 - px('1.5rem')) // the trashcan is 38px tall and the 1.5rem margin-bottom
  const width = 0.8 * bounds?.width

  const previewPanelRef = useRef(null)
  const clearButtonRef = useRef(null)
  const panelRef = useRef(null)
  useComputerPanelFocus(theFile, panelRef, clearButtonRef)

  useEffect(() => {
    return () => URL?.revokeObjectURL?.(previewURL)
  }, [previewURL])

  useEffect(() => {
    if (previewPanelRef.current && mediaTracksCheckbox) {
      previewPanelRef.current.scrollIntoView(false)
    }
  }, [mediaTracksCheckbox])

  const handlePlayerSize = useCallback(
    _event => {
      if (previewPanelRef.current === null || useStudioPlayer) return

      const player = previewPanelRef.current.querySelector('video')
      let boundingBox = {width, height}
      if (document.fullscreenElement || document.webkitFullscreenElement) {
        boundingBox = {
          width: window.innerWidth,
          height: window.innerHeight,
        }
      }
      const sz = sizeMediaPlayer(player, theFile.type, boundingBox)
      player.style.width = sz.width
      player.style.height = sz.height
      player.style.margin = '0 auto'
      // from this sub-package, I don't have a URL to use as the
      // audio player's poster image. We can give it a background image though
      player.classList.add(isAudio(theFile.type) ? 'audio-player' : 'video-player')
    },
    [theFile, width, height],
  )

  const handleLoadedMetadata = useCallback(
    _event => {
      handlePlayerSize()
    },
    [handlePlayerSize],
  )

  useEffect(() => {
    window.addEventListener('resize', handlePlayerSize)
    return () => {
      window.removeEventListener('resize', handlePlayerSize)
    }
  }, [handlePlayerSize])

  useImperativeHandle(ref, () => ({
    updateValidationMessages,
  }));

  const buildErrorMessage = errorMessage => (
    {
      type: 'error',
      text: (
        <>
          <View as="div" display="inline-block" margin="0 xxx-small xx-small 0">
            <IconWarningSolid />
          </View>
          &nbsp;
          {errorMessage}
        </>
      )
    }
  )

  const updateValidationMessages = (file) => {
    setFileDropMessages(
      file ? [] : [buildErrorMessage(CHOOSE_FILE_TO_UPLOAD)]
    )
    setFileNameMessages(
      file?.title?.trim() ? [] : [buildErrorMessage(ENTER_FILE_NAME)]
    )
  }

  const handleFileChange = file => {
    setFile(file)
    setHasUploadedFile(!!file)
    setPreviewURL(file ? URL.createObjectURL(file) : null)
    if (file) {
      updateValidationMessages(file)
    }
  }

  const handleFileNameChange = fileName => {
    theFile.title = fileName
    setFile(theFile)
    if (fileName?.trim()) {
      updateValidationMessages(theFile)
    }
  }

  if (hasUploadedFile) {
    const fileBaseType = theFile.type.split('/')[0] ?? 'video'
    return (
      <div style={{position: 'relative'}} ref={previewPanelRef}>
        <Flex direction="row-reverse" margin="none none medium">
          <Flex.Item>
            <Button
              elementRef={el => {
                clearButtonRef.current = el
              }}
              onClick={() => {
                handleFileChange(null)
              }}
              renderIcon={IconTrashLine}
            >
              <ScreenReaderContent>{CLEAR_FILE_TEXT}</ScreenReaderContent>
            </Button>
          </Flex.Item>
        </Flex>
        <View
          as="div"
          textAlign="center"
          margin="0 auto"
          width={useStudioPlayer ? width : undefined}
          height={useStudioPlayer ? height : undefined}
        >
          {/* avi, wma, and wmv files won't load from a blob URL */}
          {!(isPreviewable(theFile.type) && previewURL) ? (
            <>
              <IconVideoLine size="medium" data-testid="preview-video-icon" />
              <Text as="p" weight="normal">
                {formatMessage('No preview is available for this file.')}
              </Text>
            </>
          ) : useStudioPlayer ? (
            <StudioPlayer
              src={{src: theFile, type: `${fileBaseType}/object`}}
              hideFullScreen={!(document.fullscreenEnabled || document.webkitFullscreenEnabled)}
              disableStorage
            />
          ) : (
            <MediaPlayer
              sources={[{label: theFile.name, src: previewURL, type: theFile.type}]}
              hideFullScreen={!(document.fullscreenEnabled || document.webkitFullscreenEnabled)}
              onLoadedMetadata={handleLoadedMetadata}
            />
          )}
        </View>
        <View display="block" padding="medium 0 0">
          <TextInput
            renderLabel={formatMessage('File name')}
            placeholder={formatMessage('File name')}
            value={theFile.title}
            onChange={(_e, fileName) => {
              handleFileNameChange(fileName)
            }}
            messages={fileNameMessages}
          />
        </View>
        {(isVideo(theFile.type) || isAudio(theFile.type)) && (
          <>
            <View display="block" padding="medium medium medium 0">
              <div data-testid="mediaTracks-checkbox">
                <Checkbox
                  onChange={event => setMediaTracksCheckbox(event.target.checked)}
                  checked={mediaTracksCheckbox}
                  label={ADD_CLOSED_CAPTIONS_OR_SUBTITLES}
                  value="mediaTracks"
                />
              </div>
            </View>
            {mediaTracksCheckbox && (
              <Suspense
                fallback={
                  <View as="div" margin="small 0 0">
                    <Spinner data-testid="loading-spinner" renderTitle="" />
                  </View>
                }
              >
                <ClosedCaptionPanel
                  data-testid="ClosedCaptionPanel"
                  userLocale={userLocale}
                  liveRegion={liveRegion}
                  uploadMediaTranslations={uploadMediaTranslations}
                  updateSubtitles={updateSubtitles}
                  mountNode={mountNode}
                />
              </Suspense>
            )}
          </>
        )}
      </div>
    )
  }

  return (
    <div ref={panelRef} style={{marginBottom: '1.875rem'}}>
      <FileDrop
        accept={accept}
        onDropAccepted={([file]) => {
          file.title = file.name
          handleFileChange(file)
        }}
        onDropRejected={() => {
          setFileDropMessages(
            [buildErrorMessage(SELECT_SUPPORTED_FILE_TYPE)]
          )
        }}
        messages={fileDropMessages}
        renderLabel={
          <Billboard
            heading={label}
            hero={<RocketSVG width="3em" height="3em" />}
            message={DRAG_DROP_CLICK_TO_BROWSE}
          />
        }
      />
    </div>
  )
})

ComputerPanel.propTypes = {
  accept: oneOfType([string, arrayOf(string)]),
  hasUploadedFile: bool,
  label: string.isRequired,
  liveRegion: func,
  setFile: func.isRequired,
  setHasUploadedFile: func.isRequired,
  theFile: instanceOf(File),
  uploadMediaTranslations: translationShape,
  updateSubtitles: func.isRequired,
  bounds: shape({
    width: number.isRequired,
    height: number.isRequired,
  }),
  userLocale: string.isRequired,
  mountNode: oneOfType([element, func]),
  useStudioPlayer: bool,
}

export default ComputerPanel;

