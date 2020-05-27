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

import React, {useEffect, useRef, useState} from 'react'
import {arrayOf, bool, func, instanceOf, oneOfType, string} from 'prop-types'
import {StyleSheet, css} from 'aphrodite'

import {FileDrop} from '@instructure/ui-forms'
import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y'
import {IconTrashLine} from '@instructure/ui-icons'
import {Img, Text, TruncateText} from '@instructure/ui-elements'
import {Flex, View} from '@instructure/ui-layout'
import {VideoPlayer} from '@instructure/ui-media-player'

import {RocketSVG, useComputerPanelFocus, useSizeVideoPlayer} from '@instructure/canvas-media'

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
      resolve(<VideoPlayer sources={sources} />)
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
  label
}) {
  const [messages, setMessages] = useState([])
  const [preview, setPreview] = useState({preview: null, isLoading: false})

  useEffect(() => {
    if (!theFile || preview.isLoading || preview.preview || preview.error) return

    async function getPreview() {
      setPreview({preview: null, isLoading: true})
      try {
        const preview = await readFile(theFile)
        setPreview({preview, isLoading: false})
        if (isImage(theFile.type)) {
          // we need the preview to know the image size to show the placeholder
          theFile.preview = preview
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

  const previewPanelRef = useRef(null)
  const {playerWidth, playerHeight} = useSizeVideoPlayer(
    theFile,
    previewPanelRef,
    preview.isLoading
  )

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
            aria-label={formatMessage('{filename} text preview', {filename: theFile.name})}
          >
            <TruncateText maxLines={21}>{preview.preview}</TruncateText>
          </View>
        )
      } else if (isAudioOrVideo(theFile.type)) {
        return preview.preview
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
        {isAudioOrVideo(theFile.type) ? (
          <View
            as="div"
            height={playerHeight}
            width={playerWidth}
            textAlign="center"
            margin="0 auto"
          >
            {renderPreview()}
          </View>
        ) : (
          <View as="div" height="300px" width="300px" margin="0 auto">
            {renderPreview()}
          </View>
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
  label: string.isRequired
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
