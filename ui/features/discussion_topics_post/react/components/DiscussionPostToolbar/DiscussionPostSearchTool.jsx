/*
 * Copyright (C) 2021 - present Instructure, Inc.
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

import {IconButton} from '@instructure/ui-buttons'
import {useScope as createI18nScope} from '@canvas/i18n'
import {IconSearchLine, IconTroubleLine} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import React from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {TextInput} from '@instructure/ui-text-input'
import {breakpointsShape} from '@canvas/with-breakpoints'
import {Flex} from '@instructure/ui-flex'

const I18n = createI18nScope('discussions_posts')

const getClearButton = buttonProperties => {
  if (!buttonProperties.searchTerm?.length) return

  return (
    <IconButton
      type="button"
      size="small"
      withBackground={false}
      withBorder={false}
      screenReaderLabel={I18n.t('Clear search')}
      onClick={buttonProperties.handleClear}
      data-testid="clear-search-button"
    >
      <IconTroubleLine />
    </IconButton>
  )
}

const DiscussionPostSearchTool = props => {
  const clearButton = () => {
    return getClearButton({
      handleClear: () => {
        props.onSearchChange('')
      },
      searchTerm: props.searchTerm,
    })
  }

  const searchElementText = props.discussionAnonymousState
    ? I18n.t('Search entries...')
    : I18n.t('Search entries or author...')

  return (
    <Flex
      as="span"
      display="block"
      className="discussions-search-filter"
      padding={props.breakpoints.mobileOnly ? 'xx-small' : '0'}
    >
      <TextInput
        data-testid="search-filter"
        onChange={event => {
          props.onSearchChange(event.target.value)
        }}
        renderLabel={<ScreenReaderContent>{searchElementText}</ScreenReaderContent>}
        value={props.searchTerm}
        renderBeforeInput={<IconSearchLine display="block" />}
        renderAfterInput={clearButton}
        placeholder={searchElementText}
        shouldNotWrap={true}
      />
    </Flex>
  )
}

DiscussionPostSearchTool.propTypes = {
  onSearchChange: PropTypes.func,
  searchTerm: PropTypes.string,
  discussionAnonymousState: PropTypes.string,
  breakpoints: breakpointsShape,
}

export default DiscussionPostSearchTool
