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

import {Button, IconButton} from '@instructure/ui-buttons'
import {ChildTopic} from '../../../graphql/ChildTopic'
import {debounce} from 'lodash'
import {Flex} from '@instructure/ui-flex'
import {FormFieldGroup} from '@instructure/ui-form-field'
import {GroupsMenu} from '../GroupsMenu/GroupsMenu'
import I18n from 'i18n!discussions_posts'
import {
  IconArrowDownLine,
  IconArrowUpLine,
  IconCircleArrowUpLine,
  IconSearchLine,
  IconTroubleLine
} from '@instructure/ui-icons'
import PropTypes from 'prop-types'

import React, {useContext, useCallback, useMemo} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SearchContext} from '../../utils/constants'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'

export const getMenuConfig = props => {
  const options = {
    all: () => I18n.t('All'),
    unread: () => I18n.t('Unread')
  }
  if (props.enableDeleteFilter) {
    options.deleted = () => I18n.t('Deleted')
  }

  return options
}

const getClearButton = props => {
  if (!props.searchTerm.length) return

  return (
    <IconButton
      type="button"
      size="small"
      withBackground={false}
      withBorder={false}
      screenReaderLabel="Clear search"
      onClick={props.handleClear}
      data-testid="clear-search-button"
    >
      <IconTroubleLine />
    </IconButton>
  )
}

export const DiscussionPostToolbar = props => {
  const {searchTerm, setSearchTerm} = useContext(SearchContext)

  const debouncedSave = useCallback(
    debounce(nextValue => props.onSearchChange(nextValue), 500),
    [] // will be created only once initially
  )

  const handleChange = event => {
    const {value: nextValue} = event.target
    // Even though handleChange is created on each render and executed
    // it references the same debouncedSave that was created initially
    setSearchTerm(nextValue)
    debouncedSave(nextValue)
  }

  const handleClear = useCallback(() => {
    setSearchTerm('')
    debouncedSave('')
  }, [debouncedSave, setSearchTerm])

  const clearButton = useMemo(() => {
    return getClearButton({handleClear, searchTerm})
  }, [handleClear, searchTerm])

  return (
    <View maxWidth="56.875em">
      <Flex width="100%">
        <Flex.Item align="start" shouldGrow>
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t('Discussion Actions')}</ScreenReaderContent>}
            vAlign="middle"
            layout="columns"
          >
            {props.childTopics && <GroupsMenu width="10px" childTopics={props.childTopics} />}
            <TextInput
              data-testid="search-filter"
              onChange={handleChange}
              renderLabel={
                <ScreenReaderContent>{I18n.t('Search entries or author')}</ScreenReaderContent>
              }
              value={searchTerm}
              renderBeforeInput={<IconSearchLine inline={false} />}
              renderAfterInput={clearButton}
              placeholder={I18n.t('Search entries or author...')}
              shouldNotWrap
              width="308px"
            />

            <SimpleSelect
              renderLabel={<ScreenReaderContent>{I18n.t('Filter by')}</ScreenReaderContent>}
              defaultValue={props.selectedView}
              onChange={props.onViewFilter}
              width="120px"
            >
              <SimpleSelect.Group renderLabel={I18n.t('View')}>
                {Object.entries(getMenuConfig(props)).map(([viewOption, viewOptionLabel]) => (
                  <SimpleSelect.Option id={viewOption} key={viewOption} value={viewOption}>
                    {viewOptionLabel.call()}
                  </SimpleSelect.Option>
                ))}
              </SimpleSelect.Group>
            </SimpleSelect>

            <Tooltip
              renderTip={
                props.sortDirection === 'desc' ? I18n.t('Newest First') : I18n.t('Oldest First')
              }
              width="78px"
              data-testid="sortButtonTooltip"
            >
              <Button
                onClick={props.onSortClick}
                renderIcon={
                  props.sortDirection === 'desc' ? (
                    <IconArrowDownLine data-testid="DownArrow" />
                  ) : (
                    <IconArrowUpLine data-testid="UpArrow" />
                  )
                }
                data-testid="sortButton"
              >
                {I18n.t('Sort')}
                <ScreenReaderContent>
                  {props.sortDirection === 'asc'
                    ? I18n.t('Sorted by Ascending')
                    : I18n.t('Sorted by Descending')}
                </ScreenReaderContent>
              </Button>
            </Tooltip>
          </FormFieldGroup>
        </Flex.Item>
        <Flex.Item align="end">
          <FormFieldGroup
            description={<ScreenReaderContent>{I18n.t('Checkbox examples')}</ScreenReaderContent>}
            vAlign="middle"
            layout="columns"
          >
            <Button
              onClick={() => {
                window.scrollTo(0, 0)
              }}
              renderIcon={<IconCircleArrowUpLine />}
              data-testid="topButton"
            >
              {I18n.t('Top')}
            </Button>
          </FormFieldGroup>
        </Flex.Item>
      </Flex>
    </View>
  )
}

export default DiscussionPostToolbar

DiscussionPostToolbar.propTypes = {
  childTopics: PropTypes.arrayOf(ChildTopic.shape),
  selectedView: PropTypes.string,
  sortDirection: PropTypes.string,
  onSearchChange: PropTypes.func,
  onViewFilter: PropTypes.func,
  onSortClick: PropTypes.func
}

DiscussionPostToolbar.defaultProps = {
  sortDirection: 'desc'
}
