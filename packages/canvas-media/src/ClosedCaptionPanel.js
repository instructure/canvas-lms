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

import {Button} from '@instructure/ui-buttons'
import {IconDownloadLine, IconPlusSolid, IconTrashLine} from '@instructure/ui-icons'
import {Flex} from '@instructure/ui-layout'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {Text} from '@instructure/ui-elements'

import SingleSelect from './SingleSelect'

// TODO:
//   - Consider an alternate step based workflow for this.
//   - Working file selector for choose file button
//   - Ellipsis long file names
//   - Get current subtitles from API
//   - Upload new subtitles via API
//   - Download existing subtitles via download button
//   - Delete existing subtitles locally and via API
//   - Figure out fix for dynamic translations (ex: 'delete %{filename}')

export default function ClosedCaptionPanel({languages, liveRegion, uploadMediaTranslations}) {
  // eslint-disable-next-line no-unused-vars
  const [subtitles, setSubtitles] = useState([
    {id: 1, language: 'English', fileName: 'english.srt'},
    {id: 2, language: 'Belarusian', fileName: 'belarusian.srt'}
  ])

  const {
    CLOSED_CAPTIONS_LANGUAGE_HEADER,
    CLOSED_CAPTIONS_FILE_NAME_HEADER,
    CLOSED_CAPTIONS_ACTIONS_HEADER,
    CLOSED_CAPTIONS_ADD_SUBTITLE,
    CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER,
    CLOSED_CAPTIONS_CHOOSE_FILE,
    CLOSED_CAPTIONS_SELECT_LANGUAGE
  } = uploadMediaTranslations.UploadMediaStrings

  const selectOptions = [
    {id: 'none_selected', label: CLOSED_CAPTIONS_SELECT_LANGUAGE},
    ...languages
  ]

  return (
    <div>
      <Flex justifyItems="end">
        <Flex.Item>
          <Button variant="primary" icon={IconPlusSolid}>
            <Text aria-hidden="true">{CLOSED_CAPTIONS_ADD_SUBTITLE}</Text>
            <ScreenReaderContent>{CLOSED_CAPTIONS_ADD_SUBTITLE_SCREENREADER}</ScreenReaderContent>
          </Button>
        </Flex.Item>
      </Flex>

      <Flex direction="column">
        <Flex.Item>
          <div style={{borderBottom: '1px solid grey'}}>
            <Flex justifyItems="space-between" padding="medium 0 xx-small 0">
              <Flex.Item textAlign="start" size="200px">
                <Text weight="bold">{CLOSED_CAPTIONS_LANGUAGE_HEADER}</Text>
              </Flex.Item>
              <Flex.Item textAlign="start">
                <Text weight="bold">{CLOSED_CAPTIONS_FILE_NAME_HEADER}</Text>
              </Flex.Item>
              <Flex.Item textAlign="end" shrink grow>
                <Text weight="bold">{CLOSED_CAPTIONS_ACTIONS_HEADER}</Text>
              </Flex.Item>
            </Flex>
          </div>
        </Flex.Item>

        <Flex.Item overflowY="visible" padding="small 0 0 0">
          <Flex justifyItems="space-between">
            <Flex.Item size="200px">
              <div style={{paddingRight: '10px'}}>
                <SingleSelect
                  liveRegion={liveRegion}
                  options={selectOptions}
                  renderLabel={
                    <ScreenReaderContent>{CLOSED_CAPTIONS_SELECT_LANGUAGE}</ScreenReaderContent>
                  }
                />
              </div>
            </Flex.Item>
            <Flex.Item textAlign="start">
              <Button>{CLOSED_CAPTIONS_CHOOSE_FILE}</Button>
            </Flex.Item>
            <Flex.Item textAlign="end" shrink grow>
              <Button variant="icon" icon={IconTrashLine}>
                <ScreenReaderContent>TODO WHAT TO CALL THIS?</ScreenReaderContent>
              </Button>
            </Flex.Item>
          </Flex>
        </Flex.Item>

        {subtitles.map(cc => (
          <Flex.Item overflowY="visible" padding="small 0 0 0" key={cc.id}>
            <Flex justifyItems="space-between">
              <Flex.Item textAlign="start" size="200px">
                <Text>{cc.language}</Text>
              </Flex.Item>
              <Flex.Item textAlign="start">
                <Text>{cc.fileName}</Text>
              </Flex.Item>
              <Flex.Item textAlign="end" shrink grow>
                <Button variant="icon" icon={IconDownloadLine}>
                  <ScreenReaderContent>Download {cc.fileName}</ScreenReaderContent>
                </Button>
                <Button variant="icon" icon={IconTrashLine}>
                  <ScreenReaderContent>Delete {cc.fileName}</ScreenReaderContent>
                </Button>
              </Flex.Item>
            </Flex>
          </Flex.Item>
        ))}
      </Flex>
    </div>
  )
}
