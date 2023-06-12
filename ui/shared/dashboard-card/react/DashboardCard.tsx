// @ts-nocheck
/*
 * Copyright (C) 2015 - present Instructure, Inc.
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

import React, {MouseEventHandler, useCallback, useEffect, useRef, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import axios from '@canvas/axios'

import DashboardCardAction from './DashboardCardAction'
import CourseActivitySummaryStore from './CourseActivitySummaryStore'
import DashboardCardMenu from './DashboardCardMenu'
import PublishButton from './PublishButton'
import {showConfirmUnfavorite} from './ConfirmUnfavoriteCourseModal'
import {showFlashError} from '@canvas/alerts/react/FlashAlert'
import instFSOptimizedImageUrl from '../util/instFSOptimizedImageUrl'
import {ConnectDragSource, ConnectDropTarget} from 'react-dnd'

const I18n = useI18nScope('dashcards')

export type DashboardCardHeaderHeroProps = {
  image?: string
  backgroundColor?: string
  hideColorOverlays?: boolean
  onClick?: MouseEventHandler<HTMLElement>
}

export const DashboardCardHeaderHero = ({
  image,
  backgroundColor,
  hideColorOverlays,
  onClick,
}: DashboardCardHeaderHeroProps) => {
  if (image) {
    return (
      <div
        className="ic-DashboardCard__header_image"
        style={{backgroundImage: `url(${instFSOptimizedImageUrl(image, {x: 262, y: 146})})`}}
      >
        <div
          className="ic-DashboardCard__header_hero"
          style={{backgroundColor, opacity: hideColorOverlays ? 0 : 0.6}}
          onClick={onClick}
          aria-hidden="true"
        />
      </div>
    )
  }

  return (
    <div
      className="ic-DashboardCard__header_hero"
      style={{backgroundColor}}
      onClick={onClick}
      aria-hidden="true"
    />
  )
}

export type DashboardCardProps = {
  id: string
  backgroundColor?: string
  shortName: string
  originalName: string
  courseCode: string
  assetString: string
  term?: string
  href: string
  links: any[] // TODO: improve type
  image?: string
  handleColorChange?: (color: string) => void
  hideColorOverlays?: boolean
  isDragging?: boolean
  isFavorited?: boolean
  connectDragSource?: ConnectDragSource
  connectDropTarget?: ConnectDropTarget
  moveCard?: (assetString: string, atIndex: number, callback: () => void) => void
  onConfirmUnfavorite: (id: string) => void
  totalCards?: number
  position?: number | (() => number)
  enrollmentType?: string
  observee?: string
  published?: boolean
  canChangeCoursePublishState?: boolean
  defaultView?: string
  pagesUrl?: string
  frontPageTitle?: string
  onPublishedCourse?: (id: string) => void
}

export const DashboardCard = ({
  id,
  backgroundColor = '#394B58',
  shortName,
  originalName,
  courseCode,
  assetString,
  term,
  href,
  links = [],
  image,
  handleColorChange = () => {},
  hideColorOverlays,
  isDragging,
  isFavorited,
  connectDragSource = c => c,
  connectDropTarget = c => c,
  moveCard = () => {},
  onConfirmUnfavorite,
  totalCards = 0,
  position = 0,
  enrollmentType,
  observee,
  published,
  canChangeCoursePublishState,
  defaultView,
  pagesUrl,
  frontPageTitle,
  onPublishedCourse = () => {},
}: DashboardCardProps) => {
  const handleNicknameChange = nickname => setNicknameInfo(getNicknameInfo(nickname))

  const getNicknameInfo = (nickname: string) => ({
    nickname,
    originalName,
    courseId: id,
    onNicknameChange: handleNicknameChange,
  })

  const [nicknameInfo, setNicknameInfo] = useState(getNicknameInfo(shortName))
  const [course, setCourse] = useState(CourseActivitySummaryStore.getStateForCourse(id))
  const settingsToggle = useRef<HTMLButtonElement | null>()

  const handleStoreChange = useCallback(
    () => setCourse(CourseActivitySummaryStore.getStateForCourse(id)),
    [id]
  )

  useEffect(() => {
    CourseActivitySummaryStore.addChangeListener(handleStoreChange)
    return () => CourseActivitySummaryStore.removeChangeListener(handleStoreChange)
  }, [handleStoreChange])

  // ===============
  //    ACTIONS
  // ===============

  const getCardPosition = () => (typeof position === 'function' ? position() : position)

  const headerClick: MouseEventHandler = e => {
    e.preventDefault()
    window.location.assign(href)
  }

  const handleMove = (asset: string, atIndex: number) => {
    if (moveCard) {
      moveCard(asset, atIndex, () => settingsToggle.current?.focus())
    }
  }

  const handleUnfavorite = () => {
    const modalProps = {
      courseId: id,
      courseName: originalName,
      onConfirm: removeCourseFromFavorites,
    }
    showConfirmUnfavorite(modalProps)
  }

  // ===============
  //    HELPERS
  // ===============

  const unreadCount = (icon: string, stream?: any[]) => {
    const activityType = {
      'icon-announcement': 'Announcement',
      'icon-assignment': 'Message',
      'icon-discussion': 'DiscussionTopic',
    }[icon]

    const itemStream = stream || []
    const streamItem = itemStream.find(
      item =>
        // only return 'Message' type if category is 'Due Date' (for assignments)
        item.type === activityType &&
        (activityType !== 'Message' || item.notification_category === I18n.t('Due Date'))
    )

    // TODO: unread count is always 0 for assignments (see CNVS-21227)
    return streamItem ? streamItem.unread_count : 0
  }

  const calculateMenuOptions = () => {
    const cardPosition = getCardPosition()
    const isFirstCard = cardPosition === 0
    const isLastCard = cardPosition === totalCards - 1
    return {
      canMoveLeft: !isFirstCard,
      canMoveRight: !isLastCard,
      canMoveToBeginning: !isFirstCard,
      canMoveToEnd: !isLastCard,
    }
  }

  const removeCourseFromFavorites = () => {
    const url = `/api/v1/users/self/favorites/courses/${id}`
    axios
      .delete(url)
      .then(response => {
        if (response.status === 200) {
          onConfirmUnfavorite(id)
        }
      })
      .catch(() =>
        showFlashError(I18n.t('We were unable to remove this course from your favorites.'))
      )
  }

  const updatePublishedCourse = () => {
    if (onPublishedCourse) onPublishedCourse(id)
  }

  // ===============
  //    RENDERING
  // ===============

  const linksForCard = () =>
    links.map(link => {
      if (link.hidden) return null

      const screenReaderLabel = `${link.label} - ${nicknameInfo.nickname}`
      return (
        <DashboardCardAction
          unreadCount={unreadCount(link.icon, course?.stream)}
          iconClass={link.icon}
          linkClass={link.css_class}
          path={link.path}
          screenReaderLabel={screenReaderLabel}
          key={link.path}
        />
      )
    })

  const renderHeaderButton = () => {
    const reorderingProps = {
      handleMove,
      currentPosition: getCardPosition(),
      lastPosition: totalCards - 1,
      menuOptions: calculateMenuOptions(),
    }

    return (
      <div>
        <div
          className="ic-DashboardCard__header-button-bg"
          style={{backgroundColor, opacity: hideColorOverlays ? 1 : 0}}
        />
        <DashboardCardMenu
          afterUpdateColor={(c: string) => handleColorChange(`#${c}`)}
          currentColor={backgroundColor}
          nicknameInfo={nicknameInfo}
          assetString={assetString}
          onUnfavorite={handleUnfavorite}
          isFavorited={isFavorited}
          {...reorderingProps}
          trigger={
            <button
              type="button"
              className="Button Button--icon-action-rev ic-DashboardCard__header-button"
              ref={c => {
                settingsToggle.current = c
              }}
            >
              <i className="icon-more" aria-hidden="true" />
              <span className="screenreader-only">
                {I18n.t('Choose a color or course nickname or move course card for %{course}', {
                  course: nicknameInfo.nickname,
                })}
              </span>
            </button>
          }
        />
      </div>
    )
  }

  const dashboardCard = (
    <div
      className="ic-DashboardCard"
      style={{opacity: isDragging ? 0 : 1}}
      aria-label={originalName}
    >
      <div className="ic-DashboardCard__header">
        <span className="screenreader-only">
          {image
            ? I18n.t('Course image for %{course}', {course: nicknameInfo.nickname})
            : I18n.t('Course card color region for %{course}', {
                course: nicknameInfo.nickname,
              })}
        </span>
        <DashboardCardHeaderHero
          image={image}
          backgroundColor={backgroundColor}
          hideColorOverlays={hideColorOverlays}
          onClick={headerClick}
        />
        <a href={href} className="ic-DashboardCard__link">
          <div className="ic-DashboardCard__header_content">
            <h3 className="ic-DashboardCard__header-title ellipsis" title={originalName}>
              <span style={{color: backgroundColor}}>{nicknameInfo.nickname}</span>
            </h3>
            <div className="ic-DashboardCard__header-subtitle ellipsis" title={courseCode}>
              {courseCode}
            </div>
            <div className="ic-DashboardCard__header-term ellipsis" title={term}>
              {term || null}
            </div>
            {enrollmentType === 'ObserverEnrollment' && observee && (
              <div className="ic-DashboardCard__header-term ellipsis" title={observee}>
                {I18n.t('Observing: %{observee}', {observee})}
              </div>
            )}
          </div>
        </a>
        {!published && canChangeCoursePublishState && (
          <PublishButton
            courseNickname={nicknameInfo.nickname}
            defaultView={defaultView}
            pagesUrl={pagesUrl}
            frontPageTitle={frontPageTitle}
            courseId={id}
            onSuccess={updatePublishedCourse}
          />
        )}
        {renderHeaderButton()}
      </div>
      <nav
        className="ic-DashboardCard__action-container"
        aria-label={I18n.t('Actions for %{course}', {course: nicknameInfo.nickname})}
      >
        {linksForCard()}
      </nav>
    </div>
  )

  return connectDragSource(connectDropTarget(dashboardCard))
}

export default DashboardCard
