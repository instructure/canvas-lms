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
import {arrayOf, bool, func, instanceOf, oneOfType, string} from 'prop-types'

import {Billboard} from '@instructure/ui-billboard'
import {Button} from '@instructure/ui-buttons'
import {FileDrop} from '@instructure/ui-forms'
import {Flex, View} from '@instructure/ui-layout'
import {IconTrashLine} from '@instructure/ui-icons'
import {PresentationContent, ScreenReaderContent} from '@instructure/ui-a11y'
import {Text} from '@instructure/ui-elements'
import {VideoPlayer} from '@instructure/ui-media-player'

import RocketSVG from './RocketSVG'
import translationShape from './translationShape'

export default function ComputerPanel({
  accept,
  hasUploadedFile,
  label,
  setFile,
  setHasUploadedFile,
  theFile,
  uploadMediaTranslations
}) {
  const [messages, setMessages] = useState([])
  if (hasUploadedFile) {
    const sources = [{label: theFile.name, src: URL.createObjectURL(theFile)}]
    return (
      <>
        <Flex direction="row-reverse" margin="none none medium">
          <Flex.Item>
            <Button
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
        <View as="div" height="100%" width="100%" textAlign="center">
          <VideoPlayer sources={sources} />
        </View>
      </>
    )
  }

  return (
    <div>
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
}

ComputerPanel.propTypes = {
  accept: oneOfType([string, arrayOf(string)]),
  hasUploadedFile: bool,
  label: string.isRequired,
  setFile: func.isRequired,
  setHasUploadedFile: func.isRequired,
  theFile: instanceOf(File),
  uploadMediaTranslations: translationShape
}
