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
import {bool, element, func, oneOf, oneOfType, string} from 'prop-types'
import formatMessage from '../../../format-message'
import {Flex} from '@instructure/ui-flex'
import {View} from '@instructure/ui-view'
import {TextInput} from '@instructure/ui-text-input'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {IconButton} from '@instructure/ui-buttons'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {ICON_MAKER_ICONS} from '../instructure_icon_maker/svg/constants'
import {
  IconLinkLine,
  IconFolderLine,
  IconImageLine,
  IconDocumentLine,
  IconAttachMediaLine,
  IconSearchLine,
  IconXLine,
} from '@instructure/ui-icons'

const DEFAULT_FILTER_SETTINGS = {
  contentSubtype: 'all',
  contentType: 'links',
  sortValue: 'date_added',
  searchString: '',
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
    <SimpleSelect.Option key="links" id="links" value="links" renderBeforeLabel={IconLinkLine}>
      {formatMessage('Links')}
    </SimpleSelect.Option>,
  ]

  if (userContextType === 'course' && contentType !== 'links' && contentSubtype !== 'all') {
    options.push(
      <SimpleSelect.Option
        key="course_files"
        id="course_files"
        value="course_files"
        renderBeforeLabel={IconFolderLine}
      >
        {fileLabelFromContext('course')}
      </SimpleSelect.Option>
    )
  }

  if (userContextType === 'group' && contentType !== 'links' && contentSubtype !== 'all') {
    options.push(
      <SimpleSelect.Option
        key="group_files"
        id="group_files"
        value="group_files"
        renderBeforeLabel={IconFolderLine}
      >
        {fileLabelFromContext('group')}
      </SimpleSelect.Option>
    )
  }

  // Icon Maker icons are only stored in course folders.
  if (contentSubtype !== ICON_MAKER_ICONS) {
    options.push(
      <SimpleSelect.Option
        key="user_files"
        id="user_files"
        value="user_files"
        renderBeforeLabel={IconFolderLine}
      >
        {fileLabelFromContext(
          contentType === 'links' || contentSubtype === 'all' ? 'files' : 'user'
        )}
      </SimpleSelect.Option>
    )
  }

  return options
}

function renderType(
  contentType,
  contentSubtype,
  mountNode,
  onChange,
  userContextType,
  containingContextType
) {
  // Check containingContextType so that we always show context links
  if (containingContextType === 'course' || containingContextType === 'group') {
    return (
      <SimpleSelect
        data-testid="filter-content-type"
        mountNode={mountNode}
        renderLabel={<ScreenReaderContent>{formatMessage('Content Type')}</ScreenReaderContent>}
        assistiveText={formatMessage('Use arrow keys to navigate options.')}
        onChange={(e, selection) => {
          const changed = {contentType: selection.value}
          if (contentType === 'links') {
            // when changing away from links, go to all user files
            changed.contentSubtype = 'all'
          }
          onChange(changed)
        }}
        value={contentType}
      >
        {renderTypeOptions(contentType, contentSubtype, userContextType)}
      </SimpleSelect>
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

export default function Filter(props) {
  const {
    contentType,
    contentSubtype,
    mountNode,
    onChange,
    sortValue,
    searchString,
    userContextType,
    isContentLoading,
    containingContextType,
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

  const searchMessage = formatMessage('Enter at least 3 characters to search')
  const loadingMessage = formatMessage('Loading, please wait')
  const msg = isContentLoading ? loadingMessage : searchMessage
  const isEdit = contentSubtype === 'edit'
  return (
    <View display="block" direction="column">
      {!isEdit &&
        renderType(
          contentType,
          contentSubtype,
          mountNode,
          onChange,
          userContextType,
          containingContextType
        )}
      {contentType !== 'links' && (
        <Flex margin="small none none none">
          <Flex.Item shouldGrow={true} shouldShrink={true} margin="none xx-small none none">
            <SimpleSelect
              data-testid="filter-content-subtype"
              mountNode={mountNode}
              renderLabel={
                <ScreenReaderContent>{formatMessage('Content Subtype')}</ScreenReaderContent>
              }
              assistiveText={formatMessage('Use arrow keys to navigate options.')}
              onChange={(e, selection) => {
                const changed = {contentSubtype: selection.value}
                if (changed.contentSubtype === 'all') {
                  // when flipped to All, the context needs to be user
                  // so we can get media_objects, which are all returned in the user context
                  changed.contentType = 'user_files'
                } else if (changed.contentSubtype === ICON_MAKER_ICONS) {
                  // Icon Maker icons only belong to Courses.
                  changed.contentType = 'course_files'
                }
                onChange(changed)
              }}
              value={contentSubtype}
            >
              <SimpleSelect.Option id="images" value="images" renderBeforeLabel={IconImageLine}>
                {formatMessage('Images')}
              </SimpleSelect.Option>

              <SimpleSelect.Option
                id="documents"
                value="documents"
                renderBeforeLabel={IconDocumentLine}
              >
                {formatMessage('Documents')}
              </SimpleSelect.Option>

              <SimpleSelect.Option id="media" value="media" renderBeforeLabel={IconAttachMediaLine}>
                {formatMessage('Media')}
              </SimpleSelect.Option>

              {props.use_rce_icon_maker && (
                <SimpleSelect.Option
                  id={ICON_MAKER_ICONS}
                  value={ICON_MAKER_ICONS}
                  renderBeforeLabel={IconImageLine}
                >
                  {formatMessage('Icon Maker Icons')}
                </SimpleSelect.Option>
              )}

              <SimpleSelect.Option id="all" value="all">
                {formatMessage('All')}
              </SimpleSelect.Option>
            </SimpleSelect>
          </Flex.Item>
          {contentSubtype !== 'all' && (
            <Flex.Item shouldGrow={true} shouldShrink={true} margin="none none none xx-small">
              <SimpleSelect
                data-testid="filter-sort-by"
                mountNode={mountNode}
                renderLabel={<ScreenReaderContent>{formatMessage('Sort By')}</ScreenReaderContent>}
                assistiveText={formatMessage('Use arrow keys to navigate options.')}
                onChange={(e, selection) => {
                  onChange({sortValue: selection.value})
                }}
                value={sortValue}
              >
                <SimpleSelect.Option id="date_added" value="date_added">
                  {formatMessage('Date Added')}
                </SimpleSelect.Option>
                <SimpleSelect.Option id="alphabetical" value="alphabetical">
                  {formatMessage('Alphabetical')}
                </SimpleSelect.Option>
              </SimpleSelect>
            </Flex.Item>
          )}
        </Flex>
      )}
      <View as="div" margin="small none none none">
        <TextInput
          renderLabel={<ScreenReaderContent>{formatMessage('Search')}</ScreenReaderContent>}
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
   * `mountNode` is where INSTUI popups should mount. This is necessary for them
   * to work correctly when the RCE is in fullscreen
   */
  mountNode: oneOfType([element, func]),

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
  isContentLoading: bool,

  /**
   * The page context
   */
  containingContextType: oneOf(['user', 'course', 'group']),

  /**
   * Should include Icon Maker?
   */
  use_rce_icon_maker: bool,
}
