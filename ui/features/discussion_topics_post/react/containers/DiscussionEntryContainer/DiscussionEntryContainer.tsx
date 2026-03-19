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

import {AnonymousUser} from '../../../graphql/AnonymousUser'
import {AuthorInfo} from '../../components/AuthorInfo/AuthorInfo'
import {DeletedPostMessage} from '../../components/DeletedPostMessage/DeletedPostMessage'
import {PostMessage} from '../../components/PostMessage/PostMessage'
import PropTypes from 'prop-types'
import React, {useContext, useEffect, useRef, useCallback, useMemo, useState} from 'react'
import {getDisplayName, userNameToShow} from '../../utils'
import {SearchContext} from '../../utils/constants'
import {Attachment} from '../../../graphql/Attachment'
import {User} from '../../../graphql/User'
import {Flex} from '@instructure/ui-flex'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {ReplyPreview} from '../../components/ReplyPreview/ReplyPreview'
import theme from '@instructure/canvas-theme'
import WithBreakpoints, {breakpointsShape} from '@canvas/with-breakpoints'
import {useScope as useI18nScope} from '@canvas/i18n'
import useHighlightStore from '../../hooks/useHighlightStore'

// @ts-expect-error TS7031 (typescriptify)
const DiscussionEntryContainerBase = ({breakpoints, ...props}) => {
  const I18n = useI18nScope('discussion_topics_post')
  const {searchTerm} = useContext(SearchContext)

  const focusableElementRef = useRef(null)

  const addReplyRef = useHighlightStore(state => state.addReplyRef)
  const removeRef = useHighlightStore(state => state.removeReplyRef)
  const replyRefs = useHighlightStore(state => state.replyRefs)
  const clearHighlighted = useHighlightStore(state => state.clearHighlighted)
  const highlightEl = useHighlightStore(state => state.highlightEl)

  const [urlSearch, setUrlSearch] = useState(window.location.search)

  useEffect(() => {
    const handleUrlChange = () => {
      setUrlSearch(window.location.search)
    }

    window.addEventListener('popstate', handleUrlChange)
    const originalPushState = window.history.pushState
    const originalReplaceState = window.history.replaceState

    window.history.pushState = function (...args) {
      originalPushState.apply(this, args)
      handleUrlChange()
    }

    window.history.replaceState = function (...args) {
      originalReplaceState.apply(this, args)
      handleUrlChange()
    }

    return () => {
      window.removeEventListener('popstate', handleUrlChange)
      window.history.pushState = originalPushState
      window.history.replaceState = originalReplaceState
    }
  }, [])

  const targetEntryId = useMemo(() => {
    return new URLSearchParams(urlSearch).get('entry_id')
  }, [urlSearch])

  useEffect(() => {
    if (
      props.discussionEntry?._id &&
      focusableElementRef.current &&
      targetEntryId &&
      props.discussionEntry._id === targetEntryId
    ) {
      const timeoutId = setTimeout(() => {
        // @ts-expect-error TS18047 (typescriptify)
        focusableElementRef.current.focus()
        // @ts-expect-error TS18047 (typescriptify)
        focusableElementRef.current.scrollIntoView({
          behavior: 'smooth',
          block: 'center',
        })
      }, 100)
      return () => clearTimeout(timeoutId)
    }
  }, [props.discussionEntry?._id, targetEntryId])

  useEffect(() => {
    // TODO: Check the root entry if this is necessary to keep track of
    if (props.discussionEntry?._id && focusableElementRef.current) {
      addReplyRef(props.discussionEntry._id, focusableElementRef.current)
    }

    return () => {
      removeRef(props.discussionEntry?._id)
    }
  }, [focusableElementRef, props.discussionEntry?._id, addReplyRef, removeRef])

  const handleBlur = useCallback(
    // @ts-expect-error TS7006 (typescriptify)
    event => {
      const nextEl = event.relatedTarget

      const replyRefsArray = Array.from(replyRefs.values())

      if (
        !nextEl ||
        (!replyRefsArray.some(ref => ref === nextEl) && !event.target.contains(nextEl))
      ) {
        clearHighlighted()
      }
    },
    [replyRefs, clearHighlighted],
  )

  const handleFocus = useCallback(
    // @ts-expect-error TS7006 (typescriptify)
    event => {
      highlightEl(event.target)
    },
    [highlightEl],
  )

  useEffect(() => {
    // This component is also used in the main topic view and doesn't have an entry id
    if (!props.discussionEntry?._id) {
      return
    }

    if (focusableElementRef.current) {
      // @ts-expect-error TS2339 (typescriptify)
      focusableElementRef.current.addEventListener('blur', handleBlur)
      // @ts-expect-error TS2339 (typescriptify)
      focusableElementRef.current.addEventListener('focus', handleFocus)

      return () => {
        // @ts-expect-error TS18047 (typescriptify)
        focusableElementRef.current.removeEventListener('blur', handleBlur)
        // @ts-expect-error TS18047 (typescriptify)
        focusableElementRef.current.removeEventListener('focus', handleFocus)
      }
    }
  }, [handleBlur, handleFocus, props.discussionEntry?._id])

  // @ts-expect-error TS7006 (typescriptify)
  const getDeletedDisplayName = discussionEntry => {
    const editor = discussionEntry.editor
    const author = discussionEntry.author
    const anonymousAuthor = discussionEntry.anonymousAuthor
    if (editor) {
      if (author) {
        return userNameToShow(
          editor.displayName || editor.shortName,
          author._id,
          editor.courseRoles,
        )
      }
      if (anonymousAuthor) {
        return userNameToShow(
          editor.displayName || editor.shortName,
          anonymousAuthor._id,
          editor.courseRoles,
        )
      }
    } else {
      return getDisplayName(discussionEntry)
    }
  }

  if (props.deleted) {
    // Adding a focusable element if the deleted entry has subentries
    return (
      <div
        ref={el => {
          if (el) {
            // @ts-expect-error TS2322 (typescriptify)
            focusableElementRef.current = el
            if (props.discussionEntry.subentriesCount) {
              el.tabIndex = 0
            }
          }
        }}
      >
        <DeletedPostMessage
          deleterName={getDeletedDisplayName(props.discussionEntry)}
          // @ts-expect-error TS2322 (typescriptify)
          timingDisplay={props.timingDisplay}
          deletedTimingDisplay={props.editedTimingDisplay}
        >
          {props.children}
        </DeletedPostMessage>
      </div>
    )
  }

  const hasAuthor = Boolean(props.author || props.anonymousAuthor)
  const displayedAuthor = props.anonymousAuthor
    ? props.anonymousAuthor.shortName
    : props.author
      ? props.author.displayName
      : 'Unknown Author'

  const description = props.isTopic
    ? I18n.t('Post by %{displayedAuthor} from %{date}', {
        displayedAuthor,
        date: props.createdAt.split('T')[0],
      })
    : I18n.t('Reply to Post by %{displayedAuthor} from %{date}', {
        displayedAuthor,
        date: props.createdAt.split('T')[0],
      })

  const depth = props.discussionEntry?.depth || 0
  const threadMode = (depth > 1 && !searchTerm) || props.threadParent
  const hrMarginLeftRem = -2 - (depth - 1) * 1.5

  const direction = breakpoints.desktopNavOpen ? 'row' : 'column-reverse'
  const postUtilitiesAlign = breakpoints.desktopNavOpen && !threadMode ? 'start' : 'stretch'
  const additionalSeparatorStyles = breakpoints.mobileOnly
    ? {width: '100vw', marginLeft: `${hrMarginLeftRem}rem`}
    : {}
  let authorInfoPadding = '0 0 0 x-small'
  let postUtilitiesMargin = '0 0 x-small 0'
  let postMessagePaddingNoAuthor = '0 x-small x-small x-small'
  let postMessagePadding = '0 x-small 0 x-small'

  if (breakpoints.desktopNavOpen) {
    postUtilitiesMargin = threadMode ? '0 0 x-small small' : '0'
    authorInfoPadding = threadMode ? '0 0 small xx-small' : '0'
    postMessagePadding = props.isTopic ? '0 0 small xx-small' : '0 0 0 xx-large'
    postMessagePaddingNoAuthor = '0 0 small small'
  } else if (breakpoints.tablet) {
    postMessagePadding = '0 xx-small xx-small'
    postMessagePaddingNoAuthor = '0 xx-small xx-small'
  }

  return (
    <>
      <Flex
        direction="column"
        data-authorid={props.author?._id}
        data-entry-wrapper-id={props.discussionEntry?._id}
        aria-label={description} // Add aria-label for screen readers
        elementRef={el => {
          if (el?.parentElement) {
            el.parentElement.tabIndex = 0
            // @ts-expect-error TS2322 (typescriptify)
            focusableElementRef.current = el.parentElement
          }
        }}
      >
        <Flex.Item shouldGrow={true} shouldShrink={true} overflowY="visible">
          <Flex direction={props.isTopic ? direction : 'row'}>
            {hasAuthor && (
              <Flex.Item
                overflowY="visible"
                shouldGrow={true}
                shouldShrink={true}
                padding={authorInfoPadding}
              >
                <AuthorInfo
                  author={props.author}
                  threadParent={props.threadParent}
                  anonymousAuthor={props.anonymousAuthor}
                  editor={props.editor}
                  isUnread={props.isUnread}
                  isForcedRead={props.isForcedRead}
                  isSplitView={props.isSplitView}
                  createdAt={props.timingDisplay}
                  delayedPostAt={props.delayedPostAt}
                  editedTimingDisplay={props.editedTimingDisplay}
                  lastReplyAtDisplay={props.lastReplyAtDisplay}
                  isTopic={props.isTopic}
                  isTopicAuthor={props.isTopicAuthor}
                  discussionEntryVersions={props.discussionEntry?.discussionEntryVersions || []}
                  reportTypeCounts={props.discussionEntry?.reportTypeCounts}
                  threadMode={threadMode}
                  toggleUnread={props.toggleUnread}
                  breakpoints={breakpoints}
                  published={props.discussionTopic?.published}
                  isAnnouncement={props.discussionTopic?.isAnnouncement}
                  isPinned={props.isPinned}
                  pinnedBy={props.pinnedBy}
                />
              </Flex.Item>
            )}
            <Flex.Item
              align={postUtilitiesAlign}
              margin={hasAuthor ? postUtilitiesMargin : '0'}
              overflowX="visible"
              overflowY="visible"
              padding="xxx-small 0 0 0"
              shouldGrow={!hasAuthor}
            >
              {props.postUtilities}
            </Flex.Item>
          </Flex>
        </Flex.Item>
        <Flex.Item
          padding={hasAuthor ? postMessagePadding : postMessagePaddingNoAuthor}
          overflowY="visible"
          overflowX="visible"
        >
          {props.quotedEntry && <ReplyPreview {...props.quotedEntry} />}
          <PostMessage
            isTopic={props.isTopic}
            threadMode={threadMode && !props.isTopic}
            discussionEntry={props.discussionEntry}
            discussionAnonymousState={props.discussionTopic?.anonymousState}
            canReplyAnonymously={props.discussionTopic?.canReplyAnonymously}
            title={props.title}
            message={props.message}
            attachment={props.attachment}
            isEditing={props.isEditing}
            onSave={props.onSave}
            onCancel={props.onCancel}
            isSplitView={props.isSplitView}
            discussionTopic={props.discussionTopic}
          >
            {props.attachment && (
              <View as="div" padding="small none none">
                <Link href={props.attachment.url}>{props.attachment.displayName}</Link>
              </View>
            )}
            {props.children}
          </PostMessage>
        </Flex.Item>
      </Flex>
      {!props.isTopic && (
        <hr
          data-testid="post-separator"
          style={{
            height: theme.borders.widthSmall,
            borderColor: '#E8EAEC',
            margin: `${theme.spacing.medium} 0`,
            ...additionalSeparatorStyles,
          }}
        />
      )}
    </>
  )
}

DiscussionEntryContainerBase.propTypes = {
  isTopic: PropTypes.bool,
  postUtilities: PropTypes.node,
  author: User.shape,
  anonymousAuthor: AnonymousUser.shape,
  children: PropTypes.node,
  title: PropTypes.string,
  discussionEntry: PropTypes.object,
  discussionTopic: PropTypes.object,
  message: PropTypes.string,
  isEditing: PropTypes.bool,
  onSave: PropTypes.func,
  onCancel: PropTypes.func,
  isSplitView: PropTypes.bool,
  editor: User.shape,
  isUnread: PropTypes.bool,
  isForcedRead: PropTypes.bool,
  createdAt: PropTypes.string,
  timingDisplay: PropTypes.string,
  editedTimingDisplay: PropTypes.string,
  lastReplyAtDisplay: PropTypes.string,
  deleted: PropTypes.bool,
  isTopicAuthor: PropTypes.bool,
  threadParent: PropTypes.bool,
  quotedEntry: PropTypes.object,
  attachment: Attachment.shape,
  toggleUnread: PropTypes.func,
  breakpoints: breakpointsShape,
  delayedPostAt: PropTypes.string,
  isPinned: PropTypes.bool,
  pinnedBy: User.shape,
}

DiscussionEntryContainerBase.defaultProps = {
  deleted: false,
  threadParent: false,
  breakpoints: breakpointsShape,
}

export const DiscussionEntryContainer = WithBreakpoints(DiscussionEntryContainerBase)
