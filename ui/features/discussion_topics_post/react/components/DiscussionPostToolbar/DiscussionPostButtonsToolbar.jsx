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

import {Button} from '@instructure/ui-buttons'
import {ChildTopic} from '../../../graphql/ChildTopic'
import {Flex} from '@instructure/ui-flex'
import {GroupsMenu} from '../GroupsMenu/GroupsMenu'
import {useScope as createI18nScope} from '@canvas/i18n'
import {
  IconArrowDownLine,
  IconArrowOpenDownLine,
  IconArrowOpenUpLine,
  IconArrowUpLine,
  IconGroupLine,
  IconMoreSolid,
  IconPermissionsLine,
  IconAiLine,
} from '@instructure/ui-icons'
import PropTypes from 'prop-types'
import {
  CURRENT_USER,
  DiscussionManagerUtilityContext,
  isSpeedGraderInTopUrl,
} from '../../utils/constants'
import React, {useContext, useState} from 'react'
import {ScreenReaderContent} from '@instructure/ui-a11y-content'
import {SplitScreenButton} from './SplitScreenButton'
import {Tooltip} from '@instructure/ui-tooltip'
import {AnonymousAvatar} from '@canvas/discussions/react/components/AnonymousAvatar/AnonymousAvatar'
import {ExpandCollapseThreadsButton} from './ExpandCollapseThreadsButton'
import ItemAssignToManager from '@canvas/context-modules/differentiated-modules/react/Item/ItemAssignToManager'
import {breakpointsShape} from '@canvas/with-breakpoints'
import {Drilldown} from '@instructure/ui-drilldown'
import {getGroupDiscussionUrl} from '../../utils'
import SortOrderDropDown from './SortOrderDropDown'

const I18n = createI18nScope('discussions_posts')

const DiscussionPostButtonsToolbar = props => {
  const [showAssignToTray, setShowAssignToTray] = useState(false)
  const [moreOpened, setMoreOpened] = useState(false)
  const {translationLanguages, showTranslationControl, setShowTranslationControl} = useContext(
    DiscussionManagerUtilityContext,
  )

  const handleClose = () => setShowAssignToTray(false)

  const toggleTranslateText = () => {
    setShowTranslationControl(!showTranslationControl)
  }

  const translationText = props.isAnnouncement
    ? I18n.t('Translate Announcement')
    : I18n.t('Translate Discussion')

  const translationOptionText = showTranslationControl
    ? I18n.t('Turn off Translation')
    : translationText

  const renderGroup = () =>
    props.childTopics?.length &&
    props.isAdmin && (
      <span className="discussions-post-toolbar-groupsMenu">
        <GroupsMenu width="10px" childTopics={props.childTopics} />
      </span>
    )

  const renderSort = () => {
    if (props.discDefaultSortEnabled) {
      return (
        <SortOrderDropDown
          isLocked={props.isSortOrderLocked}
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

  const renderSplitScreen = () =>
    !isSpeedGraderInTopUrl && (
      <SplitScreenButton
        setUserSplitScreenPreference={props.setUserSplitScreenPreference}
        userSplitScreenPreference={props.userSplitScreenPreference}
        closeView={props.closeView}
        useChangedIcon={true}
        display="block"
      />
    )

  const renderAssignToButton = () =>
    !isSpeedGraderInTopUrl &&
    props.manageAssignTo &&
    props.showAssignTo && (
      <Button
        width="100%"
        display="block"
        color="primary"
        data-testid="manage-assign-to"
        renderIcon={IconPermissionsLine}
        onClick={() => setShowAssignToTray(!showAssignToTray)}
      >
        {I18n.t('Assign To')}
      </Button>
    )

  const renderExpandsThreads = () => (
    <ExpandCollapseThreadsButton
      isExpanded={props.isExpanded || (props.discDefaultExpandEnabled && props.isExpandedLocked)}
      onCollapseRepliesToggle={props.onCollapseRepliesToggle}
      showText={true}
      tooltipEnabled={props.breakpoints.ICEDesktop}
      disabled={
        props.userSplitScreenPreference ||
        (props.discDefaultExpandEnabled && props.isExpandedLocked)
      }
      expandedLocked={props.isExpandedLocked}
    />
  )

  const renderAvatar = () =>
    props.discussionAnonymousState &&
    ENV.current_user_is_student && (
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
    )

  const renderTrigger = () => {
    return props.breakpoints.mobileOnly ? (
      <Button style={{width: '100%'}} display="block">
        <Flex gap="small" justifyItems="center">
          {I18n.t('More')}
          {moreOpened ? <IconArrowOpenUpLine /> : <IconArrowOpenDownLine />}
        </Flex>
      </Button>
    ) : (
      <Button display="block" style={{width: '100%'}} renderIcon={IconMoreSolid} />
    )
  }

  const renderGroups = () => {
    return props.childTopics?.map(childTopic => {
      return (
        <Drilldown.Option
          key={childTopic._id}
          id={childTopic._id}
          value={childTopic.contextName}
          onOptionClick={() => {
            window.location.href = getGroupDiscussionUrl(childTopic.contextId, childTopic._id)
          }}
        >
          {childTopic.contextName}
        </Drilldown.Option>
      )
    })
  }

  const createDrillDownOptions = () => {
    const options = []
    const childTopicSize = props.childTopics?.length
    if (childTopicSize >= 0 && props.isAdmin) {
      options.push(
        <Drilldown.Option
          id="maingroup"
          key="maingroup"
          subPageId="Group"
          disabled={!childTopicSize}
          description={!childTopicSize ? 'There are no groups in this group set' : null}
        >
          <Flex gap="small">
            <IconGroupLine />
            {I18n.t('Group')}
          </Flex>
        </Drilldown.Option>,
      )
    }
    if (ENV.user_can_summarize && !props.isSummaryEnabled) {
      options.push(
        <Drilldown.Option
          id="summarize"
          value="summarize"
          key="summarize"
          disabled={false}
          onOptionClick={props.onSummarizeClick}
        >
          <Flex gap="small">
            <IconAiLine />
            {I18n.t('Summarize')}
          </Flex>
        </Drilldown.Option>,
      )
    }
    if (translationLanguages.current.length > 0) {
      options.push(
        <Drilldown.Option
          id="translation"
          value="translation"
          key="translation"
          disabled={false}
          onOptionClick={toggleTranslateText}
        >
          <Flex gap="small">
            <IconAiLine />
            {translationOptionText}
          </Flex>
        </Drilldown.Option>,
      )
    }
    return options
  }

  const renderButtonDrillDown = options =>
    options?.length > 0 && (
      <Drilldown
        rootPageId="Main"
        width={props.breakpoints.mobileOnly ? '92vw' : '280px'}
        maxHeight="100vh"
        placement="bottom start"
        trigger={renderTrigger()}
        defaultShow={false}
        onToggle={_event => {
          setMoreOpened(!moreOpened)
        }}
        disabled={false}
      >
        <Drilldown.Page id="Main">{options}</Drilldown.Page>
        <Drilldown.Page id="Group" key="group" renderTitle={I18n.t('Group')} disabled={false}>
          {props.childTopics && [...renderGroups()]}
        </Drilldown.Page>
      </Drilldown>
    )

  const renderButtons = () => {
    const buttonsDirection = props.breakpoints.mobileOnly ? 'column' : 'row'
    const drillDownOptions = createDrillDownOptions()
    const buttonsDesktop = [
      renderButtonDrillDown(drillDownOptions),
      renderSort(),
      renderSplitScreen(),
      renderExpandsThreads(),
      renderAvatar(),
      renderAssignToButton(),
    ]

    const buttonsMobile = () => {
      if (window.ENV?.FEATURES?.discussion_default_sort) {
        if (ENV.current_user_is_student) {
          return [renderExpandsThreads(), renderGroup()]
        } else {
          return [
            renderAssignToButton(),
            renderExpandsThreads(),
            renderButtonDrillDown(drillDownOptions),
          ]
        }
      } else {
        if (ENV.current_user_is_student) {
          return [renderExpandsThreads(), renderSort(), renderGroup()]
        } else {
          return [
            renderAssignToButton(),
            renderExpandsThreads(),
            renderButtonDrillDown(drillDownOptions),
            renderSort(),
          ]
        }
      }
    }

    const padding = props.breakpoints.mobileOnly ? 'xx-small' : 'xxx-small'

    return (
      <Flex
        wrap="wrap"
        direction={buttonsDirection}
        gap={props.breakpoints.mobileOnly ? '0' : 'small'}
        justifyItems="start"
        width="100%"
        height="100%"
        padding="xxx-small 0"
      >
        {(props.breakpoints.mobileOnly ? buttonsMobile() : buttonsDesktop).map((button, idx) => {
          return button ? (
            <Flex.Item
              shouldGrow={false}
              shouldShrink={true}
              key={button.key || idx}
              padding={padding}
            >
              {button}
            </Flex.Item>
          ) : null
        })}
      </Flex>
    )
  }

  return (
    <>
      <Flex width="100%" wrap="wrap" alignItems="start">
        <Flex.Item shouldGrow={true}>{renderButtons()}</Flex.Item>
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
    </>
  )
}

DiscussionPostButtonsToolbar.propTypes = {
  isAdmin: PropTypes.bool,
  canEdit: PropTypes.bool,
  isGraded: PropTypes.bool,
  childTopics: PropTypes.arrayOf(ChildTopic.shape),
  sortDirection: PropTypes.string,
  onSortClick: PropTypes.func,
  onCollapseRepliesToggle: PropTypes.func,
  discussionAnonymousState: PropTypes.string,
  discussionTitle: PropTypes.string,
  discussionId: PropTypes.string,
  typeName: PropTypes.string,
  setUserSplitScreenPreference: PropTypes.func,
  userSplitScreenPreference: PropTypes.bool,
  onSummarizeClick: PropTypes.func,
  isSummaryEnabled: PropTypes.bool,
  closeView: PropTypes.func,
  pointsPossible: PropTypes.number,
  manageAssignTo: PropTypes.bool,
  isCheckpointed: PropTypes.bool,
  isExpanded: PropTypes.bool,
  breakpoints: breakpointsShape,
  showAssignTo: PropTypes.bool,
  isSortOrderLocked: PropTypes.bool,
  isExpandedLocked: PropTypes.bool,
  discDefaultSortEnabled: PropTypes.bool,
  discDefaultExpandEnabled: PropTypes.bool,
  isAnnouncement: PropTypes.bool,
}

export default DiscussionPostButtonsToolbar
