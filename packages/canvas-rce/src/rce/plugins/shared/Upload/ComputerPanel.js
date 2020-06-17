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

// NOTE: if you're looking in here for the ComputerPanel that's used for
// the RCE's Media > Upload/Record Media function, it's not this one
// (though this panel can handle video with the right "accept" prop).
// See @instructure/canvas-media/src/ComputerPanel.js
// On the other hand, becuase the VideoPlayer v5 doesn't forward onLoadedMetadata
// to the underlying <video>, the sizing of the video preview is wrong.
// This isn't a big issue because (1) this isn't the panel being used to upload
// video, and (2) it will be fixed with MediaPlayer v7

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {arrayOf, bool, func, instanceOf, number, oneOfType, shape, string} from 'prop-types'
import {StyleSheet, css} from 'aphrodite'

import {FileDrop} from '@instructure/ui-forms'
import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import {px} from '@instructure/ui-utils'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y'
import {IconTrashLine} from '@instructure/ui-icons'
import {Img, Text, TruncateText} from '@instructure/ui-elements'
import {Flex, View} from '@instructure/ui-layout'
import {VideoPlayer} from '@instructure/ui-media-player'

import {RocketSVG, useComputerPanelFocus, isAudio, sizeMediaPlayer} from '@instructure/canvas-media'

import formatMessage from '../../../../format-message'
import {getIconFromType, isAudioOrVideo, isImage, isText} from '../fileTypeUtils'

function readFile(theFile) {
  const p = new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => {
      let result = reader.result
      if (isText(theFile.type) && result.length > 1000) {
        result = `${result.substr(0, 1000)}...`
      }
      resolve(result)
    }
    reader.onerror = () => {
      reject()
    }
    if (isImage(theFile.type)) {
      reader.readAsDataURL(theFile)
    } else if (isText(theFile.type)) {
      reader.readAsText(theFile)
    } else if (isAudioOrVideo(theFile.type)) {
      const sources = [{label: theFile.name, src: URL.createObjectURL(theFile)}]
      resolve(sources)
    } else {
      const icon = getIconFromType(theFile.type)
      resolve(icon)
    }
  })
  return p
}

export default function ComputerPanel({
  theFile,
  setFile,
  hasUploadedFile,
  setHasUploadedFile,
  accept,
  label,
  bounds
}) {
  const [messages, setMessages] = useState([])
  const [preview, setPreview] = useState({preview: null, isLoading: false})
  const height = 0.8 * (bounds.height - 38 - px('1.5rem')) // the trashcan is 38px tall and the 1.5rem margin-bottom
  const width = 0.8 * bounds.width

  useEffect(() => {
    if (!theFile || preview.isLoading || preview.preview || preview.error) return

    async function getPreview() {
      setPreview({preview: null, isLoading: true})
      try {
        const previewer = await readFile(theFile)
        setPreview({preview: previewer, isLoading: false})
        if (isImage(theFile.type)) {
          // we need the preview to know the image size to show the placeholder
          theFile.preview = previewer
          setFile(theFile)
        }
      } catch (ex) {
        setPreview({
          preview: null,
          error: formatMessage('An error occurred generating the file preview'),
          isLoading: false
        })
      }
    }
    getPreview()
  })

  const handleLoadedMetadata = useCallback(
    event => {
      const player = event.target
      const sz = sizeMediaPlayer(player, theFile.type, {width, height})
      player.style.width = sz.width
      player.style.height = sz.height
      // from this sub-package, I don't have a URL to use as the
      // audio player's poster image. We can give it a background image though
      player.classList.add(isAudio(theFile.type) ? 'audio-player' : 'video-player')
    },
    [theFile, width, height]
  )

  const previewPanelRef = useRef(null)
  const clearButtonRef = useRef(null)
  const panelRef = useRef(null)
  useComputerPanelFocus(theFile, panelRef, clearButtonRef)

  function renderPreview() {
    if (preview.isLoading) {
      return (
        <div aria-live="polite">
          <Text color="secondary">{formatMessage('Generating preview...')}</Text>
        </div>
      )
    } else if (preview.error) {
      return (
        <div className={css(styles.previewContainer)} aria-live="polite">
          <Text color="error">{preview.error}</Text>
        </div>
      )
    } else if (preview.preview) {
      if (isImage(theFile.type)) {
        return (
          <Img
            aria-label={formatMessage('{filename} image preview', {filename: theFile.name})}
            src={preview.preview}
            constrain="contain"
            inline={false}
          />
        )
      } else if (isText(theFile.type)) {
        return (
          <View
            as="pre"
            display="block"
            padding="x-small"
            textAlign="start"
            aria-label={formatMessage('{filename} text preview', {filename: theFile.name})}
          >
            <TruncateText maxLines={21}>{preview.preview}</TruncateText>
          </View>
        )
      } else if (isAudioOrVideo(theFile.type)) {
        return <VideoPlayer sources={preview.preview} onLoadedMetadata={handleLoadedMetadata} />
      } else {
        return (
          <div
            aria-label={formatMessage('{filename} file icon', {filename: theFile.name})}
            className={css(styles.previewContainer)}
            style={{textAlign: 'center'}}
          >
            <preview.preview size="medium" />
          </div>
        )
      }
    }
  }

  if (hasUploadedFile) {
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
                setPreview({preview: null, isLoading: false, error: null})
                setHasUploadedFile(false)
              }}
              icon={IconTrashLine}
            >
              <ScreenReaderContent>
                {formatMessage('Clear selected file: {filename}', {filename: theFile.name})}
              </ScreenReaderContent>
            </Button>
          </Flex.Item>

          <Flex.Item grow shrink>
            <PresentationContent>
              <Text>{theFile.name}</Text>
            </PresentationContent>
          </Flex.Item>
        </Flex>
        <View
          as="div"
          width={`${width}px`}
          height={`${height}px`}
          textAlign="center"
          margin="0 auto"
        >
          {renderPreview()}
        </View>
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
          setMessages(
            messages.concat({
              text: formatMessage('Invalid file type'),
              type: 'error'
            })
          )
        }}
        messages={messages}
        label={
          <Billboard
            heading={label}
            hero={<RocketSVG width="3em" height="3em" />}
            message={formatMessage('Drag and drop, or click to browse your computer')}
          />
        }
      />
    </div>
  )
}

ComputerPanel.propTypes = {
  theFile: instanceOf(File),
  setFile: func.isRequired,
  hasUploadedFile: bool,
  setHasUploadedFile: func.isRequired,
  accept: oneOfType([string, arrayOf(string)]),
  label: string.isRequired,
  bounds: shape({
    width: number,
    height: number
  })
}

ComputerPanel.defaultProps = {
  bounds: {}
}

export const styles = StyleSheet.create({
  previewContainer: {
    maxHeight: '250px',
    overflow: 'hidden',
    boxSizing: 'border-box',
    margin: '5rem .375rem 0',
    position: 'relative'
  },
  previewArea: {
    width: '100%',
    height: '100%',
    maxHeight: '250px',
    boxSizing: 'border-box',
    objectFit: 'contain',
    overflow: 'hidden'
  }
})
