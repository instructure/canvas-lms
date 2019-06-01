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

import React, {useState} from 'react'
import RocketSVG from './RocketSVG'
import {FileDrop} from '@instructure/ui-forms'
import {Billboard} from '@instructure/ui-billboard'
import {Flex, FlexItem, View} from '@instructure/ui-layout'
import {Button} from '@instructure/ui-buttons'
import { ScreenReaderContent } from '@instructure/ui-a11y'
import IconTrash from '@instructure/ui-icons/lib/Line/IconTrash'
import {bool, func, instanceOf} from 'prop-types'
import formatMessage from '../../../../format-message'
import { StyleSheet, css } from "aphrodite";

export default function ComputerPanel({
  imageFile,
  setImageFile,
  hasUploadedImage,
  setHasUploadedImage
}) {
  const [messages, setMessages] = useState([])

  if (hasUploadedImage) {
    return (
          <div aria-label={formatMessage('{filename} preview', {filename: imageFile.name})} className={css(styles.previewArea)} style={{backgroundImage: `url(${imageFile.preview})`}}>
          <div className={css(styles.buttonContainer)}><Button
            onClick={() => {
              setImageFile(null)
              setHasUploadedImage(false)
            }}
            icon={IconTrash}
          >
            <ScreenReaderContent>{formatMessage('Clear Upload')}</ScreenReaderContent>
          </Button></div>

          </div>
    )
  }
  return (
    <FileDrop
      accept="image/*"
      enablePreview
      onDropAccepted={([file]) => {
        if (messages.length) {
          setMessages([])
        }
        setImageFile(file)
        setHasUploadedImage(true)
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
          heading={formatMessage('Upload File')}
          hero={<RocketSVG width="3em" height="3em" />}
          message={formatMessage('Drag and drop, or click to browse your computer')}
        />
      }
    />
  )
}

ComputerPanel.propTypes = {
  imageFile: instanceOf(File),
  setImageFile: func.isRequired,
  hasUploadedImage: bool,
  setHasUploadedImage: func.isRequired
}

export const styles = StyleSheet.create({
  previewArea: {
    position: 'relative',
    width: '400px',
    height: '400px',
    backgroundRepeat: 'no-repeat',
    backgroundSize: 'contain',
    backgroundPosition: 'center center',
    margin: '0 auto'
  },
  buttonContainer: {
    position: 'absolute',
    top: '12px',
    right: '48px',
  }
})
