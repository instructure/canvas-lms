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

import React, {bool, useEffect, useState} from 'react'
import {func, oneOf, string} from 'prop-types'
import formatMessage from '../../../format-message'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {Select} from '@instructure/ui-forms'
import {IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y'
import {
  IconLinkLine,
  IconFolderLine,
  IconImageLine,
  IconDocumentLine,
  IconAttachMediaLine,
  IconSearchLine,
  IconXLine
} from '@instructure/ui-icons'

const DEFAULT_FILTER_SETTINGS = {
  contentSubtype: 'all',
  contentType: 'links',
  sortValue: 'date_added',
  searchString: ''
}

export function useFilterSettings(default_settings) {
  const [filterSettings, setFilterSettings] = useState(default_settings || DEFAULT_FILTER_SETTINGS)

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
    case 'files':
    default:
      return formatMessage('Files')
  }
}

function renderTypeOptions(contentType, contentSubtype, userContextType) {
  const options = [
    <option key="links" value="links" icon={IconLinkLine}>
      {formatMessage('Links')}
    </option>
  ]
  if (userContextType === 'course' && contentType !== 'links' && contentSubtype !== 'all') {
    options.push(
      <option key="course_files" value="course_files" icon={IconFolderLine}>
        {fileLabelFromContext('course')}
      </option>
    )
  }
  if (userContextType === 'group' && contentType !== 'links' && contentSubtype !== 'all') {
    options.push(
      <option key="group_files" value="group_files" icon={IconFolderLine}>
        {fileLabelFromContext('group')}
      </option>
    )
  }
  options.push(
    <option key="user_files" value="user_files" icon={IconFolderLine}>
      {fileLabelFromContext(contentType === 'links' || contentSubtype === 'all' ? 'files' : 'user')}
    </option>
  )
  return options
}

function renderType(contentType, contentSubtype, onChange, userContextType) {
  if (userContextType === 'course' || userContextType === 'group') {
    return (
      <Select
        label={<ScreenReaderContent>{formatMessage('Content Type')}</ScreenReaderContent>}
        onChange={(e, selection) => {
          const changed = {contentType: selection.value}
          if (contentType === 'links') {
            // when changing away from links, go to all user files
            changed.contentSubtype = 'all'
          }
          onChange(changed)
        }}
        selectedOption={contentType}
      >
        {renderTypeOptions(contentType, contentSubtype, userContextType)}
      </Select>
    )
  } else {
    return (
      <View as="div" borderWidth="small" padding="x-small small" borderRadius="medium" width="100%">
        <ScreenReaderContent>{formatMessage('Content Type')}</ScreenReaderContent>
        {fileLabelFromContext('user', contentSubtype)}
      </View>
    )
  }
}

function shouldSearch(searchString) {
  return searchString.length === 0 || searchString.length >= 3
}

const searchMessage = formatMessage('Enter at least 3 characters to search')
const loadingMessage = formatMessage('Loading, please wait')

export default function Filter(props) {
  const {
    contentType,
    contentSubtype,
    onChange,
    sortValue,
    searchString,
    userContextType,
    isContentLoading
  } = props
  const [pendingSearchString, setPendingSearchString] = useState(searchString)
  const [searchInputTimer, setSearchInputTimer] = useState(0)

  // only run on mounting to trigger change to correct contextType
  useEffect(() => {
    onChange({contentType})
  }, []) // eslint-disable-line react-hooks/exhaustive-deps

  function doSearch(value) {
    if (shouldSearch(value)) {
      if (searchInputTimer) {
        window.clearTimeout(searchInputTimer)
        setSearchInputTimer(0)
      }
      onChange({searchString: value})
    }
  }

  function handleChangeSearch(value) {
    setPendingSearchString(value)
    if (searchInputTimer) {
      window.clearTimeout(searchInputTimer)
    }
    const tid = window.setTimeout(() => doSearch(value), 250)
    setSearchInputTimer(tid)
  }

  function handleClear() {
    handleChangeSearch('')
  }

  function renderClearButton() {
    if (pendingSearchString) {
      return (
        <IconButton
          screenReaderLabel={formatMessage('Clear')}
          onClick={handleClear}
          interaction={isContentLoading ? 'disabled' : 'enabled'}
          withBorder={false}
          withBackground={false}
          size="small"
        >
          <IconXLine />
        </IconButton>
      )
    }
    return undefined
  }

  const msg = isContentLoading ? loadingMessage : searchMessage
  return (
    <View display="block" direction="column">
      {renderType(contentType, contentSubtype, onChange, userContextType)}
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
      <View as="div" margin="small none none none">
        <TextInput
          renderLabel={
            isContentLoading ? (
              <ScreenReaderContent>{formatMessage('Loading, please wait')}</ScreenReaderContent>
            ) : (
              <ScreenReaderContent>{formatMessage('Search')}</ScreenReaderContent>
            )
          }
          renderBeforeInput={<IconSearchLine inline={false} />}
          renderAfterInput={renderClearButton()}
          messages={[{type: 'hint', text: msg}]}
          placeholder={formatMessage('Search')}
          value={pendingSearchString}
          onChange={(e, value) => handleChangeSearch(value)}
          onKeyDown={e => {
            if (e.key === 'Enter') {
              doSearch(pendingSearchString)
            }
          }}
          interaction={isContentLoading ? 'readonly' : 'enabled'}
        />
      </View>
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
  contentType: oneOf(['links', 'user_files', 'course_files', 'group_files']).isRequired,

  /**
   * `onChange` is called when any of the Filter settings are changed
   */
  onChange: func.isRequired,

  /**
   * `sortValue` defines how items in the CanvasContentTray are sorted
   */
  sortValue: string.isRequired,

  /**
   * `searchString` is used to search for matching file names. Must be >3 chars long
   */
  searchString: string.isRequired,

  /**
   * The user's context
   */
  userContextType: oneOf(['user', 'course', 'group']),

  /**
   * Is my content currently loading?
   */
  isContentLoading: bool
}
