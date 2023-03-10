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

import React, {useCallback, useEffect, useRef, useState} from 'react'
import {arrayOf, func, number, object, oneOfType, shape, string} from 'prop-types'
import {StyleSheet, css} from 'aphrodite'

import {FileDrop} from '@instructure/ui-file-drop'
import {Billboard} from '@instructure/ui-billboard'
import {Alert} from '@instructure/ui-alerts'
import {IconButton} from '@instructure/ui-buttons'
import {px} from '@instructure/ui-utils'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {IconTrashLine} from '@instructure/ui-icons'
import {Img} from '@instructure/ui-img'
import {Text} from '@instructure/ui-text'
import {TruncateText} from '@instructure/ui-truncate-text'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {MediaPlayer} from '@instructure/ui-media-player'

import {
  RocketSVG,
  useComputerPanelFocus,
  isAudio,
  isPreviewable,
  sizeMediaPlayer,
} from '@instructure/canvas-media'

import formatMessage from '../../../../format-message'
import {
  getIconFromType,
  isAudioOrVideo,
  isImage,
  isText,
  isIWork,
  getIWorkType,
} from '../fileTypeUtils'

function isPreviewableAudioOrVideo(type) {
  return isPreviewable(type) && isAudioOrVideo(type)
}

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
      reject(new Error(formatMessage('An error occured reading the file')))
    }

    if (theFile.size === 0) {
      // canvas will reject uploading an empty file
      reject(new Error(formatMessage('You may not upload an empty file.')))
    }
    if (isImage(theFile.type)) {
      reader.readAsDataURL(theFile)
    } else if (isText(theFile.type)) {
      reader.readAsText(theFile)
    } else if (isPreviewableAudioOrVideo(theFile.type)) {
      const sources = [{label: theFile.name, src: URL.createObjectURL(theFile), type: theFile.type}]
      resolve(sources)
    } else {
      let type = theFile.type
      // Native JS File API returns empty string if it can't determine the type
      if (type === '' && isIWork(theFile.name)) {
        type = getIWorkType(theFile.name)
      }
      const icon = getIconFromType(type)
      resolve(icon)
    }
  })
  return p
}

export default function ComputerPanel({theFile, setFile, setError, accept, label, bounds}) {
  const [messages, setMessages] = useState([])
  const [preview, setPreview] = useState({preview: null, isLoading: false})
  // the trashcan is 38px tall and the 1.5rem margin-bottom
  // the 350 is to guarantee the video doesn't oveflow into the copyright UI,
  // which should probably be rendered here and not up in the modal because
  // dealing with Tabs and size is nearly impossible
  const height = Math.min(350, 0.8 * (bounds.height - 38 - px('1.5rem')))
  const width = 0.8 * bounds.width

  useEffect(() => {
    return () => {
      if (Array.isArray(preview?.preview)) {
        URL?.revokeObjectURL?.(preview.preview[0].src)
      }
    }
  }, [preview])

  useEffect(() => {
    if (!theFile || preview.isLoading || preview.preview || preview.error) return

    async function getPreview() {
      setPreview({preview: null, isLoading: true})
      try {
        const previewer = await readFile(theFile)
        setPreview({preview: previewer, isLoading: false})
        setError(null)
        if (isImage(theFile.type)) {
          // we need the preview to know the image size to show the placeholder
          theFile.preview = previewer
          setFile(theFile)
        }
      } catch (ex) {
        setError(ex)
        setPreview({
          preview: null,
          error: ex.message,
          isLoading: false,
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
      player.style.margin = '0 auto'
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
          <Alert variant="error">{preview.error}</Alert>
        </div>
      )
    } else if (preview.preview) {
      if (isImage(theFile.type)) {
        return (
          <Img
            aria-label={formatMessage('{filename} image preview', {filename: theFile.name})}
            src={preview.preview}
            constrain="contain"
            display="block"
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
      } else if (isPreviewableAudioOrVideo(theFile.type)) {
        return <MediaPlayer sources={preview.preview} onLoadedMetadata={handleLoadedMetadata} />
      } else {
        return (
          <div
            aria-label={formatMessage('{filename} file icon', {filename: theFile.name})}
            className={css(styles.previewContainer)}
            style={{textAlign: 'center'}}
          >
            <preview.preview size="medium" />
            <Text as="p" weight="normal">
              {formatMessage('No preview is available for this file.')}
            </Text>
          </div>
        )
      }
    }
  }

  if (theFile) {
    const filename = theFile.name
    return (
      <div style={{position: 'relative'}} ref={previewPanelRef}>
        <Flex direction="row-reverse" margin="none none medium">
          <Flex.Item>
            <IconButton
              elementRef={el => {
                clearButtonRef.current = el
              }}
              onClick={() => {
                setFile(null)
                setPreview({preview: null, isLoading: false, error: null})
              }}
              renderIcon={IconTrashLine}
              screenReaderLabel={formatMessage('Clear selected file: {filename}', {filename})}
            />
          </Flex.Item>

          <Flex.Item shouldGrow={true} shouldShrink={true}>
            <PresentationContent>
              <Text>{filename}</Text>
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
        }}
        onDropRejected={() => {
          setMessages(
            messages.concat({
              text: formatMessage('Invalid file type'),
              type: 'error',
            })
          )
        }}
        messages={messages}
        renderLabel={
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
  // instanceof File or the File object from DataTransfer which seems to be different
  theFile: object,
  setFile: func.isRequired,
  setError: func.isRequired,
  accept: oneOfType([string, arrayOf(string)]),
  label: string.isRequired,
  bounds: shape({
    width: number,
    height: number,
  }),
}

ComputerPanel.defaultProps = {
  bounds: {},
}

export const styles = StyleSheet.create({
  previewContainer: {
    maxHeight: '250px',
    overflow: 'hidden',
    boxSizing: 'border-box',
    margin: '5rem .375rem 0',
    position: 'relative',
  },
  previewArea: {
    width: '100%',
    height: '100%',
    maxHeight: '250px',
    boxSizing: 'border-box',
    objectFit: 'contain',
    overflow: 'hidden',
  },
})
