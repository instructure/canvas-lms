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
import {Flex} from '@instructure/ui-flex'
import {GroupsMenu} from '../GroupsMenu/GroupsMenu'
import {useScope as useI18nScope} from '@canvas/i18n'
import {
  IconArrowDownLine,
  IconArrowUpLine,
  IconSearchLine,
  IconTroubleLine,
  IconPermissionsLine
} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import {CURRENT_USER} from '../../utils/constants'
import React, {useState} from 'react'
import {Responsive} from '@instructure/ui-responsive'
import {responsiveQuerySizes} from '../../utils'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {SplitScreenButton} from './SplitScreenButton'
import {TextInput} from '@instructure/ui-text-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import {AnonymousAvatar} from '@canvas/discussions/react/components/AnonymousAvatar/AnonymousAvatar'
import {ExpandCollapseThreadsButton} from './ExpandCollapseThreadsButton'
import ItemAssignToTray from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToTray'

const I18n = useI18nScope('discussions_posts')

export const getMenuConfig = props => {
  const options = {
    all: () => I18n.t('All'),
    unread: () => I18n.t('Unread'),
  }
  if (props.enableDeleteFilter) {
    options.deleted = () => I18n.t('Deleted')
  }

  return options
}

const getClearButton = props => {
  if (!props.searchTerm?.length) return

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
  const [showAssignToTray, setShowAssignToTray] = useState(false)

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

    const handleClose = () => setShowAssignToTray(false)

  return (
    <Responsive
      match="media"
      query={responsiveQuerySizes({mobile: true, desktop: true})}
      props={{
        mobile: {
          direction: 'column',
          dividingMargin: '0',
          groupSelect: {
            margin: '0 xx-small 0 0',
          },
          search: {
            shouldGrow: true,
            shouldShrink: true,
            width: '100%',
          },
          filter: {
            shouldGrow: true,
            shouldShrink: true,
            width: null,
            margin: '0 xx-small 0 0',
          },
          viewSplitScreen: {
            shouldGrow: true,
            margin: '0 xx-small 0 0',
          },
          padding: 'xx-small',
        },
        desktop: {
          direction: 'row',
          dividingMargin: '0 small 0 0',
          groupSelect: {
            margin: '0 small 0 0',
          },
          search: {
            shouldGrow: true,
            shouldShrink: true,
            width: null,
          },
          filter: {
            shouldGrow: false,
            shouldShrink: false,
            width: '120px',
            margin: '0 small 0 0',
          },
          viewSplitScreen: {
            shouldGrow: false,
            margin: '0 small 0 0',
          },
          padding: 'xxx-small',
        },
      }}
      render={(responsiveProps, matches) => (
        <View maxWidth="56.875em">
          <Flex width="100%" direction={responsiveProps.direction} wrap="wrap">
            <Flex.Item
              margin={responsiveProps?.dividingMargin}
              shouldShrink={responsiveProps.shouldShrink}
            >
              <Flex>
                {/* Groups */}
                {props.childTopics?.length && props.isAdmin && (
                  <Flex.Item
                    data-testid="groups-menu-button"
                    margin={responsiveProps?.groupSelect?.margin}
                    padding={responsiveProps?.padding}
                  >
                    <span className="discussions-post-toolbar-groupsMenu">
                      <GroupsMenu width="10px" childTopics={props.childTopics} />
                    </span>
                  </Flex.Item>
                )}
                {/* Search */}
                <Flex.Item
                  shouldGrow={responsiveProps?.search?.shouldGrow}
                  shouldShrink={responsiveProps?.search?.shouldShrink}
                  padding={responsiveProps.padding}
                >
                  <span className="discussions-search-filter">
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
                      width={responsiveProps?.search?.width}
                    />
                  </span>
                </Flex.Item>
              </Flex>
            </Flex.Item>

            <Flex.Item shouldGrow={true}>
              <Flex wrap="wrap">
                {/* Filter */}
                <Flex.Item
                  margin={responsiveProps?.filter?.margin}
                  padding={responsiveProps.padding}
                  shouldGrow={responsiveProps?.filter?.shouldGrow}
                  shouldShrink={false}
                >
                  <span className="discussions-filter-by-menu">
                    <SimpleSelect
                      renderLabel={<ScreenReaderContent>{I18n.t('Filter by')}</ScreenReaderContent>}
                      defaultValue={props.selectedView}
                      onChange={props.onViewFilter}
                      width={responsiveProps?.filter?.width}
                    >
                      <SimpleSelect.Group renderLabel={I18n.t('View')}>
                        {Object.entries(getMenuConfig(props)).map(
                          ([viewOption, viewOptionLabel]) => (
                            <SimpleSelect.Option
                              id={viewOption}
                              key={viewOption}
                              value={viewOption}
                            >
                              {viewOptionLabel.call()}
                            </SimpleSelect.Option>
                          )
                        )}
                      </SimpleSelect.Group>
                    </SimpleSelect>
                  </span>
                </Flex.Item>
                {/* Sort */}
                <Flex.Item margin="0 small 0 0" padding={responsiveProps.padding}>
                  <Tooltip
                    renderTip={
                      props.sortDirection === 'desc'
                        ? I18n.t('Newest First')
                        : I18n.t('Oldest First')
                    }
                    width="78px"
                    data-testid="sortButtonTooltip"
                  >
                    <span className="discussions-sort-button">
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
                    </span>
                  </Tooltip>
                </Flex.Item>

                <Flex.Item
                  margin={responsiveProps?.viewSplitScreen?.margin}
                  padding={responsiveProps.padding}
                  shouldGrow={responsiveProps?.viewSplitScreen?.shouldGrow}
                >
                  <SplitScreenButton
                    setUserSplitScreenPreference={props.setUserSplitScreenPreference}
                    userSplitScreenPreference={props.userSplitScreenPreference}
                    closeView={props.closeView}
                    display={matches.includes('mobile') ? 'block' : 'inline-block'}
                  />
                </Flex.Item>

                {!props.userSplitScreenPreference && (
                  <Flex.Item margin="0 small 0 0" padding={responsiveProps.padding}>
                    <ExpandCollapseThreadsButton showText={!matches.includes('mobile')} />
                  </Flex.Item>
                )}
                {props.discussionAnonymousState && ENV.current_user_roles?.includes('student') && (
                  <Flex.Item shouldGrow={true}>
                    <Flex justifyItems="end">
                      <Flex.Item>
                        <Tooltip renderTip={I18n.t('This is your anonymous avatar')}>
                          <div>
                            <AnonymousAvatar addFocus="0" seedString={CURRENT_USER} />
                          </div>
                        </Tooltip>
                      </Flex.Item>
                    </Flex>
                  </Flex.Item>
                )}
                {props.canEdit && ENV.FEATURES?.differentiated_modules && !props.isAnnouncement && (
                <Flex.Item shouldGrow={true} textAlign="end">
                  <Button
                    data-testid="manage-assign-to"
                    renderIcon={IconPermissionsLine}
                    onClick={() => (setShowAssignToTray(!showAssignToTray))} >{I18n.t('Assign To')}</Button>
                </Flex.Item>
                )}
              </Flex>
            </Flex.Item>
          </Flex>
          {showAssignToTray && <ItemAssignToTray
            open={showAssignToTray}
            onClose={handleClose}
            onDismiss={handleClose}
            courseId={ENV.course_id}
            itemName={props.discussionTitle}
            itemType={props.typeName}
            iconType={props.typeName}
            pointsPossible={props.pointsPossible}
            itemContentId={props.discussionId}
            locale={ENV.LOCALE || 'en'}
            timezone={ENV.TIMEZONE || 'UTC'}
            removeDueDateInput={!props.isGraded}
          />}
        </View>
      )}
    />
  )
}

export default DiscussionPostToolbar

DiscussionPostToolbar.propTypes = {
  isAdmin: PropTypes.bool,
  canEdit: PropTypes.bool,
  isAnnouncement: PropTypes.bool,
  isGraded: PropTypes.bool,
  childTopics: PropTypes.arrayOf(ChildTopic.shape),
  selectedView: PropTypes.string,
  sortDirection: PropTypes.string,
  onSearchChange: PropTypes.func,
  onViewFilter: PropTypes.func,
  onSortClick: PropTypes.func,
  searchTerm: PropTypes.string,
  discussionTitle: PropTypes.string,
  discussionId: PropTypes.string,
  typeName: PropTypes.string,
  discussionAnonymousState: PropTypes.string,
  setUserSplitScreenPreference: PropTypes.func,
  userSplitScreenPreference: PropTypes.bool,
  closeView: PropTypes.func,
  pointsPossible: PropTypes.number,
}

DiscussionPostToolbar.defaultProps = {
  sortDirection: 'desc',
}
