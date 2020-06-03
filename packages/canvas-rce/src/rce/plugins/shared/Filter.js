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

import React, {useEffect, useState} from 'react'
import {func, oneOf, string} from 'prop-types'
import {Flex, View} from '@instructure/ui-layout'
import formatMessage from '../../../format-message'
import {Select} from '@instructure/ui-forms'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {
  IconLinkLine,
  IconFolderLine,
  IconImageLine,
  IconDocumentLine,
  IconAttachMediaLine
} from '@instructure/ui-icons'

const DEFAULT_FILTER_SETTINGS = {
  contentSubtype: 'all',
  contentType: 'links',
  sortValue: 'date_added'
}

export function useFilterSettings() {
  const [filterSettings, setFilterSettings] = useState(DEFAULT_FILTER_SETTINGS)

  function updateFilterSettings(nextSettings) {
    setFilterSettings({...filterSettings, ...nextSettings})
  }

  return [filterSettings, updateFilterSettings]
}

function fileLabelFromContext(contextType) {
  switch (contextType) {
    case 'user':
      return formatMessage('User Files')
    case 'course':
      return formatMessage('Course Files')
    case 'group':
      return formatMessage('Group Files')
    default:
      return formatMessage('Files')
  }
}

function renderType(contentType, onChange, userContextType) {
  if (userContextType === 'course') {
    return (
      <Select
        label={<ScreenReaderContent>{formatMessage('Content Type')}</ScreenReaderContent>}
        onChange={(e, selection) => {
          onChange({contentType: selection.value})
        }}
        selectedOption={contentType}
      >
        <option key="links" value="links" icon={IconLinkLine}>
          {formatMessage('Links')}
        </option>
        <option key="course_files" value="course_files" icon={IconFolderLine}>
          {fileLabelFromContext('course')}
        </option>
        <option key="user_files" value="user_files" icon={IconFolderLine}>
          {fileLabelFromContext('user')}
        </option>
      </Select>
    )
  } else {
    return (
      <View as="div" borderWidth="small" padding="x-small small" borderRadius="medium" width="100%">
        <ScreenReaderContent>{formatMessage('Content Type')}</ScreenReaderContent>
        {fileLabelFromContext('user')}
      </View>
    )
  }
}

export default function Filter(props) {
  const {contentType, contentSubtype, onChange, sortValue, userContextType} = props

  // only run on mounting to trigger change to correct contextType
  useEffect(() => {
    onChange({contentType})
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  return (
    <View display="block" direction="column">
      {renderType(contentType, onChange, userContextType)}
      {contentType !== 'links' && (
        <Flex margin="small none none none">
          <Flex.Item grow shrink margin="none xx-small none none">
            <Select
              label={<ScreenReaderContent>{formatMessage('Content Subtype')}</ScreenReaderContent>}
              onChange={(e, selection) => {
                const changed = {contentSubtype: selection.value}
                if (changed.contentSubtype === 'all') {
                  // when flipped to All, the context needs to be user
                  // so we can get media_objects, which are all returned in the user context
                  changed.contentType = 'user_files'
                }
                onChange(changed)
              }}
              selectedOption={contentSubtype}
            >
              <option value="images" icon={IconImageLine}>
                {formatMessage('Images')}
              </option>

              <option value="documents" icon={IconDocumentLine}>
                {formatMessage('Documents')}
              </option>

              <option value="media" icon={IconAttachMediaLine}>
                {formatMessage('Media')}
              </option>

              <option value="all">{formatMessage('All')}</option>
            </Select>
          </Flex.Item>

          {contentSubtype !== 'all' && (
            <Flex.Item grow shrink margin="none none none xx-small">
              <Select
                label={<ScreenReaderContent>{formatMessage('Sort By')}</ScreenReaderContent>}
                onChange={(e, selection) => {
                  onChange({sortValue: selection.value})
                }}
                selectedOption={sortValue}
              >
                <option value="date_added">{formatMessage('Date Added')}</option>
                <option value="alphabetical">{formatMessage('Alphabetical')}</option>
              </Select>
            </Flex.Item>
          )}
        </Flex>
      )}
    </View>
  )
}

Filter.propTypes = {
  /**
   * `contentSubtype` is the secondary filter setting, currently only used when
   * `contentType` is set to "files"
   */
  contentSubtype: string.isRequired,

  /**
   * `contentType` is the primary filter setting (e.g. links, files)
   */
  contentType: oneOf(['links', 'user_files', 'course_files']).isRequired,

  /**
   * `onChange` is called when any of the Filter settings are changed
   */
  onChange: func.isRequired,

  /**
   * `sortValue` defines how items in the CanvasContentTray are sorted
   */
  sortValue: string.isRequired,

  /**
   * The user's context
   */
  userContextType: oneOf(['user', 'course'])
}
