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

import {useMutation} from '@apollo/client'
import {useScope as createI18nScope} from '@canvas/i18n'
import {breakpointsShape} from '@canvas/with-breakpoints'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {Button} from '@instructure/ui-buttons'
import {Flex} from '@instructure/ui-flex'
import {IconArrowDownLine, IconArrowUpLine} from '@instructure/ui-icons'
import {Tooltip} from '@instructure/ui-tooltip'
import {View} from '@instructure/ui-view'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useState} from 'react'
import {Discussion} from '../../../graphql/Discussion'
import {UPDATE_DISCUSSION_TOPIC_PARTICIPANT} from '../../../graphql/Mutations'
import DiscussionPostButtonsToolbar from '../../components/DiscussionPostToolbar/DiscussionPostButtonsToolbar'
import DiscussionPostSearchTool from '../../components/DiscussionPostToolbar/DiscussionPostSearchTool'
import {DiscussionPostToolbar} from '../../components/DiscussionPostToolbar/DiscussionPostToolbar'
import SortOrderDropDown from '../../components/DiscussionPostToolbar/SortOrderDropDown'
import useSpeedGrader from '../../hooks/useSpeedGrader'
import {hideStudentNames} from '../../utils'
import {
  DiscussionManagerUtilityContext,
  SEARCH_TERM_DEBOUNCE_DELAY,
  SearchContext,
  isSpeedGraderInTopUrl,
} from '../../utils/constants'
import DiscussionTopicTitleContainer from '../DiscussionTopicTitleContainer/DiscussionTopicTitleContainer'

const I18n = createI18nScope('discussion_topic')

const instUINavEnabled = () => window.ENV?.FEATURES?.instui_nav
const discDefaultSortEnabled = () => window.ENV?.FEATURES?.discussion_default_sort
const discDefaultExpandEnabled = () => window.ENV?.FEATURES?.discussion_default_expand
const DiscussionTopicToolbarContainer = props => {
  const {searchTerm, filter, sort, setSearchTerm, setFilter, setSort} = useContext(SearchContext)
  const {showTranslationControl} = useContext(DiscussionManagerUtilityContext)
  const [currentSearchValue, setCurrentSearchValue] = useState(searchTerm || '')

  useEffect(() => {
    const interval = setInterval(() => {
      if (currentSearchValue !== searchTerm) {
        setSearchTerm(currentSearchValue)
      }
    }, SEARCH_TERM_DEBOUNCE_DELAY)

    return () => clearInterval(interval)
  }, [currentSearchValue, searchTerm, setSearchTerm])

  const onViewFilter = (_event, value) => {
    setFilter(value.value)
  }

  const [updateDiscussionTopicParticipant] = useMutation(UPDATE_DISCUSSION_TOPIC_PARTICIPANT)
  const {handleSwitchClick} = useSpeedGrader()
  const onSwitchLinkClick = () => {
    handleSwitchClick()
  }

  const onSortClick = () => {
    let newOrder = null
    if (sort === null) {
      newOrder = props.discussionTopic.participant.sortOrder === 'asc' ? 'desc' : 'asc'
    } else {
      newOrder = sort === 'asc' ? 'desc' : 'asc'
    }
    updateDiscussionTopicParticipant({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        sortOrder: newOrder,
      },
    }).then(() => {
      setSort(newOrder)
    })
  }
  const onExpandCollapseClick = bool => {
    updateDiscussionTopicParticipant({
      variables: {
        discussionTopicId: props.discussionTopic._id,
        expanded: bool,
      },
    })
  }

  const renderSort = () => {
    if (discDefaultSortEnabled) {
      return (
        <SortOrderDropDown
          isLocked={props.discussionTopic.sortOrderLocked}
          selectedSortType={props.sortDirection}
          onSortClick={props.onSortClick}
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
            style={{width: '100%'}}
            display="block"
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

  const getGroupsMenuTopics = () => {
    if (!props.discussionTopic.groupSet) {
      return null
    }
    if (props.discussionTopic.childTopics?.length > 0) {
      return props.discussionTopic.childTopics
    } else if (props.discussionTopic.rootTopic?.childTopics?.length > 0) {
      return props.discussionTopic.rootTopic.childTopics
    } else {
      return []
    }
  }

  const background =
    ENV?.FEATURES?.discussion_checkpoints && isSpeedGraderInTopUrl ? 'secondary' : 'primary'
  return (
    <View as="div" padding="0" margin="0 0 x-small 0" background={background}>
      {instUINavEnabled() ? (
        <>
          <Flex
            wrap="wrap"
            direction={props.breakpoints.ICEDesktop ? 'row' : 'column'}
            justifyItems="space-between"
            margin="0 0 small 0"
          >
            <Flex.Item>
              <DiscussionTopicTitleContainer
                discussionTopicTitle={props.discussionTopic.title}
                mobileHeader={!props.breakpoints.ICEDesktop}
                onViewFilter={onViewFilter}
                selectedView={filter}
                instUINavEnabled={instUINavEnabled()}
              />
            </Flex.Item>
            <Flex.Item id="Main">
              <DiscussionPostButtonsToolbar
                isAdmin={props.discussionTopic.permissions.readAsAdmin}
                canEdit={props.discussionTopic.permissions.update}
                childTopics={getGroupsMenuTopics()}
                selectedView={filter}
                sortDirection={props.discussionTopic.participant.sortOrder}
                isExpanded={props.discussionTopic.participant.expanded}
                onSearchChange={value => setCurrentSearchValue(value)}
                onViewFilter={onViewFilter}
                onSortClick={onSortClick}
                onCollapseRepliesToggle={onExpandCollapseClick}
                onTopClick={() => {}}
                searchTerm={currentSearchValue}
                discussionAnonymousState={props.discussionTopic.anonymousState}
                canReplyAnonymously={props.discussionTopic.canReplyAnonymously}
                setUserSplitScreenPreference={props.setUserSplitScreenPreference}
                userSplitScreenPreference={props.userSplitScreenPreference}
                closeView={props.closeView}
                discussionId={props.discussionTopic._id}
                typeName={props.discussionTopic.__typename?.toLowerCase()}
                discussionTitle={props.discussionTopic.title}
                pointsPossible={props.discussionTopic.assignment?.pointsPossible}
                isGraded={props.discussionTopic.assignment !== null}
                manageAssignTo={props.discussionTopic.permissions.manageAssignTo}
                isCheckpointed={props?.discussionTopic?.assignment?.checkpoints?.length > 0}
                breakpoints={props.breakpoints}
                isSortOrderLocked={props.discussionTopic.sortOrderLocked}
                isExpandedLocked={props.discussionTopic.expandedLocked}
                discDefaultSortEnabled={discDefaultSortEnabled()}
                discDefaultExpandEnabled={discDefaultExpandEnabled()}
                showAssignTo={
                  !props.discussionTopic.isAnnouncement &&
                  props.discussionTopic.contextType === 'Course' &&
                  (props.discussionTopic.assignment !== null ||
                    !props.discussionTopic.groupSet !== null)
                }
                isAnnouncement={props.discussionTopic.isAnnouncement}
              />
            </Flex.Item>
          </Flex>
          {!window.ENV?.FEATURES?.discussion_default_sort ? (
            !hideStudentNames && (
              <DiscussionPostSearchTool
                discussionAnonymousState={props.discussionTopic.anonymousState}
                onSearchChange={value => setCurrentSearchValue(value)}
                searchTerm={currentSearchValue}
                breakpoints={props.breakpoints}
              />
            )
          ) : (
            <Flex
              direction={props.breakpoints.mobileOnly ? 'column' : 'row'}
              wrap="wrap"
              gap={props.breakpoints.mobileOnly ? '0' : 'small'}
              width="100%"
              height="100%"
              padding="xxx-small 0"
            >
              <Flex.Item shouldGrow={true} shouldShrink={true}>
                {!hideStudentNames && (
                  <DiscussionPostSearchTool
                    discussionAnonymousState={props.discussionTopic.anonymousState}
                    onSearchChange={value => setCurrentSearchValue(value)}
                    searchTerm={currentSearchValue}
                    breakpoints={props.breakpoints}
                  />
                )}
              </Flex.Item>
              <Flex.Item
                shouldGrow={false}
                shouldShrink={true}
                width={props.breakpoints.mobileOnly ? '100%' : 'fit-content'}
                padding={props.breakpoints.mobileOnly ? 'xx-small' : 'xxx-small'}
              >
                {renderSort()}
              </Flex.Item>
            </Flex>
          )}
        </>
      ) : (
        <>
          <ScreenReaderContent>
            <h1>{props.discussionTopic.title}</h1>
          </ScreenReaderContent>
          <DiscussionPostToolbar
            isAdmin={props.discussionTopic.permissions.readAsAdmin}
            canEdit={props.discussionTopic.permissions.update}
            childTopics={getGroupsMenuTopics()}
            selectedView={filter}
            sortDirection={props.discussionTopic.participant.sortOrder}
            searchTerm={currentSearchValue}
            discussionAnonymousState={props.discussionTopic.anonymousState}
            canReplyAnonymously={props.discussionTopic.canReplyAnonymously}
            isExpanded={props.discussionTopic.participant.expanded}
            onSearchChange={value => setCurrentSearchValue(value)}
            onViewFilter={onViewFilter}
            onSortClick={onSortClick}
            onCollapseRepliesToggle={onExpandCollapseClick}
            onSwitchLinkClick={onSwitchLinkClick}
            setUserSplitScreenPreference={props.setUserSplitScreenPreference}
            userSplitScreenPreference={props.userSplitScreenPreference}
            closeView={props.closeView}
            discussionId={props.discussionTopic._id}
            typeName={props.discussionTopic.__typename?.toLowerCase()}
            discussionTitle={props.discussionTopic.title}
            pointsPossible={props.discussionTopic.assignment?.pointsPossible}
            isGraded={props.discussionTopic.assignment !== null}
            manageAssignTo={props.discussionTopic.permissions.manageAssignTo}
            isCheckpointed={props?.discussionTopic?.assignment?.checkpoints?.length > 0}
            isSortOrderLocked={props.discussionTopic.sortOrderLocked}
            isExpandedLocked={props.discussionTopic.expandedLocked}
            discDefaultSortEnabled={discDefaultSortEnabled()}
            discDefaultExpandEnabled={discDefaultExpandEnabled()}
            isAnnouncement={props.discussionTopic.isAnnouncement}
            showAssignTo={
              !props.discussionTopic.isAnnouncement &&
              props.discussionTopic.contextType === 'Course' &&
              (props.discussionTopic.assignment !== null ||
                !props.discussionTopic.groupSet !== null)
            }
          />
        </>
      )}
    </View>
  )
}

DiscussionTopicToolbarContainer.propTypes = {
  discussionTopic: Discussion.shape,
  setUserSplitScreenPreference: PropTypes.func,
  userSplitScreenPreference: PropTypes.bool,
  closeView: PropTypes.func,
  breakpoints: breakpointsShape,
}

export default DiscussionTopicToolbarContainer
