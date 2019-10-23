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

import React, {Suspense, useRef, useState} from 'react'
import {arrayOf, bool, func, instanceOf, oneOfType, shape, string} from 'prop-types'

import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import {Checkbox, FileDrop} from '@instructure/ui-forms'
import {Flex, View} from '@instructure/ui-layout'
import {IconTrashLine} from '@instructure/ui-icons'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y'
import {Text} from '@instructure/ui-elements'
import {VideoPlayer} from '@instructure/ui-media-player'

import LoadingIndicator from './shared/LoadingIndicator'
import RocketSVG from './RocketSVG'
import translationShape from './translationShape'
import useComputerPanelFocus from './useComputerPanelFocus'
import useSizeVideoPlayer from './useSizeVideoPlayer'

const ClosedCaptionPanel = React.lazy(() => import('./ClosedCaptionCreator'))

export default function ComputerPanel({
  accept,
  hasUploadedFile,
  label,
  languages,
  liveRegion,
  setFile,
  setHasUploadedFile,
  theFile,
  uploadMediaTranslations,
  updateSubtitles
}) {
  const {
    ADD_CLOSED_CAPTIONS_OR_SUBTITLES,
    LOADING_MEDIA
  } = uploadMediaTranslations.UploadMediaStrings
  const [messages, setMessages] = useState([])
  const [mediaTracksCheckbox, setMediaTracksCheckbox] = useState(false)

  // right-size the video player
  const previewPanelRef = useRef(null)
  const {playerWidth, playerHeight} = useSizeVideoPlayer(theFile, previewPanelRef)

  const clearButtonRef = useRef(null)
  const panelRef = useRef(null)
  useComputerPanelFocus(theFile, panelRef, clearButtonRef)

  if (hasUploadedFile) {
    const src = URL.createObjectURL(theFile)
    return (
      <div style={{position: 'relative'}} ref={previewPanelRef}>
        <Flex direction="row-reverse" margin="none none medium">
          <Flex.Item>
            <Button
              buttonRef={el => {
                clearButtonRef.current = el
              }}
              onClick={() => {
                setFile(null)
                setHasUploadedFile(false)
              }}
              icon={IconTrashLine}
            >
              <ScreenReaderContent>
                {uploadMediaTranslations.UploadMediaStrings.CLEAR_FILE_TEXT}
              </ScreenReaderContent>
            </Button>
          </Flex.Item>
          <Flex.Item grow shrink>
            <PresentationContent>
              <Text>{theFile.name}</Text>
            </PresentationContent>
          </Flex.Item>
        </Flex>
        <View as="div" width={playerWidth} height={playerHeight} textAlign="center" margin="0 auto">
          <VideoPlayer sources={[{label: theFile.name, src}]} controls={renderControls} />
        </View>
        {isVideo(theFile.type) && (
          <>
            <View display="block" padding="medium medium medium 0">
              <Checkbox
                onChange={event => setMediaTracksCheckbox(event.target.checked)}
                checked={mediaTracksCheckbox}
                label={ADD_CLOSED_CAPTIONS_OR_SUBTITLES}
                value="mediaTracks"
              />
            </View>
            {mediaTracksCheckbox && (
              <Suspense fallback={LoadingIndicator(LOADING_MEDIA)}>
                <ClosedCaptionPanel
                  languages={languages}
                  liveRegion={liveRegion}
                  uploadMediaTranslations={uploadMediaTranslations}
                  updateSubtitles={updateSubtitles}
                />
              </Suspense>
            )}
          </>
        )}
      </div>
    )
  }

  return (
    <div ref={panelRef}>
      <FileDrop
        accept={accept}
        onDropAccepted={([file]) => {
          if (messages.length) {
            setMessages([])
          }
          setFile(file)
          setHasUploadedFile(true)
        }}
        onDropRejected={() => {
          setMessages(msgs =>
            msgs.concat({
              text: uploadMediaTranslations.UploadMediaStrings.INVALID_FILE_TEXT,
              type: 'error'
            })
          )
        }}
        messages={messages}
        label={
          <Billboard
            heading={label}
            hero={<RocketSVG width="3em" height="3em" />}
            message={uploadMediaTranslations.UploadMediaStrings.DRAG_DROP_CLICK_TO_BROWSE}
          />
        }
      />
    </div>
  )

  function renderControls(VPC) {
    if (isAudio(theFile.type)) {
      return (
        <VPC>
          <VPC.PlayPauseButton />
          <VPC.Timebar />
          <VPC.Volume />
          <VPC.PlaybackSpeed />
          <VPC.TrackChooser />
        </VPC>
      )
    }
    return (
      <VPC>
        <VPC.PlayPauseButton />
        <VPC.Timebar />
        <VPC.Volume />
        <VPC.PlaybackSpeed />
        <VPC.TrackChooser />
        <VPC.SourceChooser />
        {document.fullscreenEnabled && <VPC.FullScreenButton />}
      </VPC>
    )
  }
}

function isVideo(type) {
  return /^video/.test(type)
}

function isAudio(type) {
  return /^audio/.test(type)
}

ComputerPanel.propTypes = {
  accept: oneOfType([string, arrayOf(string)]),
  hasUploadedFile: bool,
  label: string.isRequired,
  languages: arrayOf(
    shape({
      id: string,
      label: string
    })
  ),
  liveRegion: func,
  setFile: func.isRequired,
  setHasUploadedFile: func.isRequired,
  theFile: instanceOf(File),
  uploadMediaTranslations: translationShape,
  updateSubtitles: func.isRequired
}
