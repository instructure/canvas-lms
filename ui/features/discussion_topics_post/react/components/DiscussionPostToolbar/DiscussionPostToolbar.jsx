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

import ItemAssignToManager from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToManager'
import {AnonymousAvatar} from '@canvas/discussions/react/components/AnonymousAvatar/AnonymousAvatar'
import {useScope as createI18nScope} from '@canvas/i18n'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button, IconButton} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {
  IconAiLine,
  IconArrowDownLine,
  IconArrowUpLine,
  IconPermissionsLine,
  IconSearchLine,
  IconTroubleLine,
  IconAiColoredSolid,
  IconXSolid,
} from '@instructure/ui-icons'
import {Responsive} from '@instructure/ui-responsive'
import {SimpleSelect} from '@instructure/ui-simple-select'
import {TextInput} from '@instructure/ui-text-input'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import PropTypes from 'prop-types'
import React, {useContext, useState} from 'react'
import {ChildTopic} from '../../../graphql/ChildTopic'
import {hideStudentNames, responsiveQuerySizes} from '../../utils'
import {
  CURRENT_USER,
  DiscussionManagerUtilityContext,
  isSpeedGraderInTopUrl,
} from '../../utils/constants'
import {GroupsMenu} from '../GroupsMenu/GroupsMenu'
import SwitchToIndividualPostsLink from '../SwitchToIndividualPostsLink/SwitchToIndividualPostsLink'
import {TranslationTriggerModal} from '../TranslationTriggerModal/TranslationTriggerModal'
import {ExpandCollapseThreadsButton} from './ExpandCollapseThreadsButton'
import SortOrderDropDown from './SortOrderDropDown'
import {SplitScreenButton} from './SplitScreenButton'

const I18n = createI18nScope('discussions_posts')

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

const getClearButton = buttonProperties => {
  if (!buttonProperties.searchTerm?.length) return

  return (
    <IconButton
      type="button"
      size="small"
      withBackground={false}
      withBorder={false}
      screenReaderLabel="Clear search"
      onClick={buttonProperties.handleClear}
      data-testid="clear-search-button"
    >
      <IconTroubleLine />
    </IconButton>
  )
}

export const DiscussionPostToolbar = props => {
  const [showAssignToTray, setShowAssignToTray] = useState(false)
  const [isModalOpen, setModalOpen] = useState(false)
  const {
    translationLanguages,
    setShowTranslationControl,
    translateTargetLanguage,
    setTranslateTargetLanguage,
    showTranslationControl,
  } = useContext(DiscussionManagerUtilityContext)

  const [showTranslate, setShowTranslate] = useState(false)

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

  const toggleTranslateText = () => {
    if (ENV.ai_translation_improvements) {
      // If translations module is visible and discussion is translated open the modal
      if (showTranslationControl) {
        translateTargetLanguage ? setModalOpen(true) : setShowTranslationControl(false)
      } else {
        setShowTranslationControl(true)
      }
    } else {
      // Update local state
      setShowTranslate(!showTranslate)
      // Update context
      setShowTranslationControl(!showTranslate)
    }
  }

  const renderTranslate = () => {
    const text = showTranslate ? I18n.t('Hide Translate Text') : I18n.t('Translate Text')

    const translationText = I18n.t('Open Translate')

    const improvedText = showTranslationControl ? I18n.t('Close Translate') : translationText

    return (
      <Button
        onClick={toggleTranslateText}
        data-testid="translate-button"
        data-action-state={showTranslationControl ? 'disableTranslation' : 'enableTranslation'}
        renderIcon={showTranslationControl ? <IconXSolid /> : <IconAiColoredSolid />}
        color={showTranslationControl ? 'secondary' : 'ai-secondary'}
      >
        {ENV.ai_translation_improvements ? improvedText : text}
      </Button>
    )
  }

  const closeModalAndKeepTranslations = () => {
    setModalOpen(false)
    setShowTranslationControl(false)
  }

  const closeModalAndRemoveTranslations = () => {
    setModalOpen(false)
    setShowTranslationControl(false)
    setTranslateTargetLanguage(null)
  }

  const renderSort = width => {
    if (props.discDefaultSortEnabled) {
      return (
        <SortOrderDropDown
          isLocked={props.isSortOrderLocked}
          selectedSortType={props.sortDirection}
          onSortClick={props.onSortClick}
          width={width}
        />
      )
    }
    return (
      <Tooltip
        renderTip={props.sortDirection === 'desc' ? I18n.t('Newest First') : I18n.t('Oldest First')}
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
    )
  }

  const renderSwitchLink = () => {
    return (
      <SwitchToIndividualPostsLink
        onSwitchLinkClick={props.onSwitchLinkClick}
        data-testid="context-toggle-link"
      />
    )
  }

  return (
    <>
      <TranslationTriggerModal
        isModalOpen={isModalOpen}
        isAnnouncement={props.isAnnouncement}
        closeModal={() => {
          setModalOpen(false)
        }}
        closeModalAndKeepTranslations={closeModalAndKeepTranslations}
        closeModalAndRemoveTranslations={closeModalAndRemoveTranslations}
      />
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
              width: window.ENV?.FEATURES?.discussion_default_sort ? '100%' : null,
              margin: window.ENV?.FEATURES?.discussion_default_sort ? null : '0 xx-small 0 0',
            },
            viewSplitScreen: {
              shouldGrow: true,
              margin: '0 xx-small 0 0',
            },
            sortOrder: {
              shouldGrow: true,
              shouldShrink: true,
              width: '100%',
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
              width: window.ENV?.FEATURES?.discussion_default_sort ? '100%' : null,
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
            sortOrder: {
              shouldGrow: false,
              shouldShrink: false,
              margin: '0 0 0 small',
            },
            padding: 'xxx-small',
          },
        }}
        render={(responsiveProps, matches) => (
          <View maxWidth="56.875em">
            <Flex width="100%" direction={responsiveProps.direction} wrap="wrap">
              {!window.ENV?.FEATURES?.discussion_default_sort && (
                <Flex.Item
                  margin={responsiveProps?.dividingMargin}
                  shouldShrink={responsiveProps.shouldShrink}
                >
                  <Flex>
                    {/* Search */}
                    {!hideStudentNames && (
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
                            renderLabel={
                              <ScreenReaderContent>{searchElementText}</ScreenReaderContent>
                            }
                            value={props.searchTerm}
                            renderBeforeInput={<IconSearchLine display="block" />}
                            renderAfterInput={clearButton}
                            placeholder={searchElementText}
                            shouldNotWrap={true}
                            width={responsiveProps?.search?.width}
                          />
                        </span>
                      </Flex.Item>
                    )}
                  </Flex>
                </Flex.Item>
              )}
              <Flex.Item shouldGrow={true}>
                <Flex wrap="wrap">
                  {!window.ENV?.FEATURES?.discussion_default_sort && (
                    <>
                      {/* Filter */}
                      <Flex.Item
                        margin={responsiveProps?.filter?.margin}
                        padding={responsiveProps.padding}
                        shouldGrow={responsiveProps?.filter?.shouldGrow}
                        shouldShrink={false}
                      >
                        <span data-testid="toggle-filter-menu">
                          <SimpleSelect
                            renderLabel={
                              <ScreenReaderContent>{I18n.t('Filter by')}</ScreenReaderContent>
                            }
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
                                ),
                              )}
                            </SimpleSelect.Group>
                          </SimpleSelect>
                        </span>
                      </Flex.Item>
                      {/* Sort */}
                      <Flex.Item margin="0 small 0 0" padding={responsiveProps.padding}>
                        {renderSort()}
                      </Flex.Item>
                    </>
                  )}
                  {!isSpeedGraderInTopUrl && (
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
                  )}
                  {(!props.userSplitScreenPreference || isSpeedGraderInTopUrl) && (
                    <Flex.Item margin="0 small 0 0" padding={responsiveProps.padding}>
                      <ExpandCollapseThreadsButton
                        showText={!matches.includes('mobile')}
                        isExpanded={
                          props.isExpanded ||
                          (props.discDefaultExpandEnabled && props.isExpandedLocked)
                        }
                        onCollapseRepliesToggle={props.onCollapseRepliesToggle}
                        disabled={
                          props.userSplitScreenPreference ||
                          (props.discDefaultExpandEnabled && props.isExpandedLocked)
                        }
                        expandedLocked={props.isExpandedLocked}
                      />
                    </Flex.Item>
                  )}
                  {/* Groups */}
                  {props.childTopics?.length >= 0 && props.isAdmin && (
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
                  {translationLanguages.current.length > 0 && !isSpeedGraderInTopUrl && (
                    <Flex.Item margin="0 small 0 0" padding={responsiveProps.padding}>
                      {renderTranslate()}
                    </Flex.Item>
                  )}
                  {isSpeedGraderInTopUrl && window?.ENV?.FEATURES?.discussion_checkpoints && (
                    <Flex.Item
                      margin="0 small 0 0"
                      padding={responsiveProps.padding}
                      textAlign="end"
                      shouldGrow={true}
                    >
                      {renderSwitchLink()}
                    </Flex.Item>
                  )}
                  {props.discussionAnonymousState &&
                    ENV.current_user_roles?.includes('student') && (
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
                  {!isSpeedGraderInTopUrl && props.manageAssignTo && props.showAssignTo && (
                    <Flex.Item shouldGrow={true} textAlign="end">
                      <Button
                        data-testid="manage-assign-to"
                        renderIcon={IconPermissionsLine}
                        onClick={() => setShowAssignToTray(!showAssignToTray)}
                      >
                        {I18n.t('Assign To')}
                      </Button>
                    </Flex.Item>
                  )}
                </Flex>
              </Flex.Item>
              {window.ENV?.FEATURES?.discussion_default_sort && (
                <Flex.Item
                  margin={responsiveProps?.dividingMargin}
                  shouldShrink={responsiveProps.shouldShrink}
                  width="100%"
                >
                  <Flex
                    wrap="wrap"
                    width="100%"
                    direction={responsiveProps?.direction}
                    height="100%"
                    padding="xx-small 0 0 0"
                  >
                    {/* Filter */}
                    <Flex.Item
                      margin={responsiveProps?.filter?.margin}
                      padding={responsiveProps.padding}
                      shouldGrow={responsiveProps?.filter?.shouldGrow}
                      shouldShrink={false}
                    >
                      <span data-testid="toggle-filter-menu">
                        <SimpleSelect
                          id="viewSelect"
                          renderLabel={
                            <ScreenReaderContent>{I18n.t('Filter by')}</ScreenReaderContent>
                          }
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
                              ),
                            )}
                          </SimpleSelect.Group>
                        </SimpleSelect>
                      </span>
                    </Flex.Item>
                    {/* Search */}
                    {!hideStudentNames && (
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
                            renderLabel={
                              <ScreenReaderContent>{searchElementText}</ScreenReaderContent>
                            }
                            value={props.searchTerm}
                            renderBeforeInput={<IconSearchLine display="block" />}
                            renderAfterInput={clearButton}
                            placeholder={searchElementText}
                            shouldNotWrap={true}
                            width="100%"
                          />
                        </span>
                      </Flex.Item>
                    )}
                    {/* Sort */}
                    <Flex.Item
                      margin={responsiveProps?.sortOrder?.margin}
                      padding={responsiveProps.padding}
                      shouldGrow={responsiveProps?.sortOrder?.shouldGrow}
                      shouldShrink={responsiveProps?.sortOrder?.shouldShrink}
                    >
                      {renderSort(responsiveProps?.sortOrder?.width)}
                    </Flex.Item>
                  </Flex>
                </Flex.Item>
              )}
            </Flex>
            {showAssignToTray && (
              <ItemAssignToManager
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
                isCheckpointed={props.isCheckpointed}
              />
            )}
          </View>
        )}
      />
    </>
  )
}

export default DiscussionPostToolbar

DiscussionPostToolbar.propTypes = {
  isAdmin: PropTypes.bool,
  canEdit: PropTypes.bool,
  isGraded: PropTypes.bool,
  childTopics: PropTypes.arrayOf(ChildTopic.shape),
  selectedView: PropTypes.string,
  sortDirection: PropTypes.string,
  onSearchChange: PropTypes.func,
  onViewFilter: PropTypes.func,
  onSortClick: PropTypes.func,
  onCollapseRepliesToggle: PropTypes.func,
  onSwitchLinkClick: PropTypes.func,
  searchTerm: PropTypes.string,
  discussionTitle: PropTypes.string,
  discussionId: PropTypes.string,
  typeName: PropTypes.string,
  discussionAnonymousState: PropTypes.string,
  setUserSplitScreenPreference: PropTypes.func,
  userSplitScreenPreference: PropTypes.bool,
  closeView: PropTypes.func,
  pointsPossible: PropTypes.number,
  manageAssignTo: PropTypes.bool,
  isCheckpointed: PropTypes.bool,
  isExpanded: PropTypes.bool,
  isAnnouncement: PropTypes.bool,
  showAssignTo: PropTypes.bool,
  isSortOrderLocked: PropTypes.bool,
  isExpandedLocked: PropTypes.bool,
  discDefaultSortEnabled: PropTypes.bool,
  discDefaultExpandEnabled: PropTypes.bool,
}
