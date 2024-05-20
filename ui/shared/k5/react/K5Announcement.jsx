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

import React, {useCallback, useEffect, useState} from 'react'
import {useScope as useI18nScope} from '@canvas/i18n'
import * as tz from '@canvas/datetime'
import PropTypes from 'prop-types'

import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine, IconArrowOpenEndLine, IconArrowOpenStartLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {PresentationContent} from '@instructure/ui-a11y-content'
import {showFlashAlert} from '@canvas/alerts/react/FlashAlert'

import apiUserContent from '@canvas/util/jquery/apiUserContent'
import doFetchApi from '@canvas/do-fetch-api-effect'
import LoadingSkeleton from './LoadingSkeleton'
import EmptyK5Announcement, {K5AddAnnouncementButton} from './EmptyK5Announcement'
import {transformAnnouncement} from './utils'

const I18n = useI18nScope('k5_announcement')

const ANNOUNCEMENT_LOOKAHEAD_PAGE_SIZE = 2

const FAUX_ANNOUNCEMENT_ID = '_no_recent_announcments_announcement_'
const noRecentAnnouncementsFauxAnnouncement = {
  id: FAUX_ANNOUNCEMENT_ID,
}

export const K5AnnouncementLoadingMask = props => {
  const {notForHomeroom, ...rest} = props
  return (
    <div {...rest}>
      {notForHomeroom || (
        <LoadingSkeleton
          screenReaderLabel={I18n.t('Loading Homeroom Course Name')}
          margin="medium 0 small"
          width="20em"
          height="1.5em"
        />
      )}
      <LoadingSkeleton
        screenReaderLabel={I18n.t('Loading Announcement Title')}
        margin="small 0"
        width="15em"
        height="1.5em"
      />
      <LoadingSkeleton
        screenReaderLabel={I18n.t('Loading Announcement Content')}
        margin="small 0"
        width="100%"
        height="8em"
      />
    </div>
  )
}
export default function K5Announcement({
  courseId,
  courseName,
  courseUrl,
  published,
  canEdit,
  canReadAnnouncements,
  showCourseDetails,
  firstAnnouncement,
}) {
  const [loadingMore, setLoadingMore] = useState(false)
  const [homeroomAnnouncements, setHomeroomAnnouncements] = useState([
    firstAnnouncement || noRecentAnnouncementsFauxAnnouncement,
  ])
  const [currentAnnouncement, setCurrentAnnouncement] = useState(homeroomAnnouncements[0])
  const [needPrevAnnouncement, setNeedPrevAnnouncement] = useState(false)
  const [moreHomeroomAnnouncementsURL, setMoreHomeroomAnnouncementsURL] = useState(null)
  const [loadFirstBatch, setLoadFirstBatch] = useState(true)

  const fetchMoreAnnouncements = useCallback(
    async function fetchMoreAnnouncements(firstQuery = false) {
      if (!(firstQuery || moreHomeroomAnnouncementsURL)) return Promise.resolve()

      const end_date = new Date()

      // look back at most 1 year for old announcements
      const start_date = new Date()
      start_date.setFullYear(start_date.getFullYear() - 1)

      let json, link
      setLoadingMore(true)
      try {
        ;({json, link} = await doFetchApi({
          path: firstQuery ? '/api/v1/announcements' : moreHomeroomAnnouncementsURL,
          params: firstQuery && {
            active_only: true,
            context_codes: [`course_${courseId}`],
            start_date: start_date.toISOString(),
            end_date: end_date.toISOString(),
            per_page: ANNOUNCEMENT_LOOKAHEAD_PAGE_SIZE,
          },
        }))
        setMoreHomeroomAnnouncementsURL(link?.next?.url)

        const parsedAnnouncements = json
          // discard the one announcement we may already have on initial load (so it doesn't show twice)
          .filter(a => a.id !== firstAnnouncement?.id)
          .map(a => transformAnnouncement(a))
        // order of homeroomAnnouncements:
        // [most distant announcement, ..., most recent announcement, faux announcement (if present)]
        setHomeroomAnnouncements(parsedAnnouncements.reverse().concat(homeroomAnnouncements))
      } catch (ex) {
        showFlashAlert({
          message: I18n.t('Failed getting next batch of announcements.'),
          err: ex,
          type: 'error',
        })
      }
      setLoadingMore(false)
    },
    [courseId, firstAnnouncement, homeroomAnnouncements, moreHomeroomAnnouncementsURL]
  )

  const currentAnnouncementIndex = useCallback(() => {
    return homeroomAnnouncements.findIndex(a => a.id === currentAnnouncement.id)
  }, [currentAnnouncement.id, homeroomAnnouncements])

  const hasPrevAnnouncement = () => {
    const index = currentAnnouncementIndex()
    return index > 0 || loadingMore
  }

  const hasNextAnnouncement = () => {
    const index = currentAnnouncementIndex()
    return index < homeroomAnnouncements.length - 1
  }

  const noAnnouncementsAtAll = () => {
    return (
      homeroomAnnouncements.length === 1 &&
      homeroomAnnouncements[0].id === FAUX_ANNOUNCEMENT_ID &&
      !loadingMore
    )
  }

  const handlePrevAnnouncement = useCallback(() => {
    const index = currentAnnouncementIndex()
    if (index === 0) {
      setNeedPrevAnnouncement(true)
    } else {
      setCurrentAnnouncement(homeroomAnnouncements[index - 1])
      if (!loadingMore && index < 2) {
        fetchMoreAnnouncements()
      }
    }
  }, [currentAnnouncementIndex, fetchMoreAnnouncements, homeroomAnnouncements, loadingMore])

  const handleNextAnnouncement = useCallback(() => {
    const index = currentAnnouncementIndex()
    setCurrentAnnouncement(homeroomAnnouncements[index + 1])
  }, [currentAnnouncementIndex, homeroomAnnouncements])

  // on initial render, get the first page of look-ahead prev announcements
  useEffect(() => {
    if (loadFirstBatch) {
      setLoadFirstBatch(false)
      fetchMoreAnnouncements(true)
    }
  }, [fetchMoreAnnouncements, loadFirstBatch])

  // once we fetch the announcement the user asked for but we didn't have, show it
  useEffect(() => {
    if (!loadingMore && needPrevAnnouncement) {
      // we just got the next batch. process the user's request of the prev announcement
      setNeedPrevAnnouncement(false)
      handlePrevAnnouncement()
    }
  }, [handlePrevAnnouncement, loadingMore, needPrevAnnouncement])

  // we know there is another announcement but the user has clicked the prev button fast enough
  // and the network is slow enough that we don't have it in hand yet
  const fetchForNeededAnnouncementIsInFlight = () => {
    return (
      (needPrevAnnouncement || homeroomAnnouncements[0].id === FAUX_ANNOUNCEMENT_ID) && loadingMore
    )
  }

  const renderWithButtons = content => (
    <Flex
      data-testid="with-edit-button"
      alignItems="center"
      justifyItems="space-between"
      margin="medium 0 0"
      wrap="wrap"
    >
      <Flex.Item shouldGrow={true}>{content}</Flex.Item>
      {canEdit && currentAnnouncement.id !== FAUX_ANNOUNCEMENT_ID && (
        <Flex.Item margin="0 0 0 x-small">
          <IconButton
            screenReaderLabel={I18n.t('Edit announcement %{title}', {
              title: currentAnnouncement.title,
            })}
            withBackground={false}
            withBorder={false}
            href={`${currentAnnouncement.url}/edit`}
          >
            <IconEditLine />
          </IconButton>
        </Flex.Item>
      )}
      {(hasPrevAnnouncement() || hasNextAnnouncement() || loadingMore) && (
        <Flex.Item>
          <IconButton
            margin="0 0 0 x-small"
            screenReaderLabel={I18n.t('Previous announcement')}
            withBackground={true}
            withBorder={true}
            onClick={handlePrevAnnouncement}
            interaction={
              hasPrevAnnouncement() && !fetchForNeededAnnouncementIsInFlight()
                ? 'enabled'
                : 'disabled'
            }
          >
            <IconArrowOpenStartLine />
          </IconButton>
          <IconButton
            margin="0 0 0 x-small"
            screenReaderLabel={I18n.t('Next announcement')}
            withBackground={true}
            withBorder={true}
            onClick={handleNextAnnouncement}
            interaction={hasNextAnnouncement() ? 'enabled' : 'disabled'}
          >
            <IconArrowOpenEndLine />
          </IconButton>
        </Flex.Item>
      )}
    </Flex>
  )

  const renderAnnouncementTitle = () => {
    if (currentAnnouncement.id === FAUX_ANNOUNCEMENT_ID) return null
    return (
      <Flex wrap="wrap" alignItems="end">
        <Flex.Item align="start" shouldGrow={true} shoulShrink={true} margin="x-small x-small 0 0">
          <Heading level="h3">
            {canEdit || !showCourseDetails ? (
              <Link href={currentAnnouncement.url} isWithinText={false}>
                {currentAnnouncement.title}
              </Link>
            ) : (
              currentAnnouncement.title
            )}
          </Heading>
        </Flex.Item>
        {currentAnnouncement.postedDate && (
          <Flex.Item align="end" margin="x-small 0 0">
            {/* condensed makes it the same as default for h3 */}
            <Text as="div" size="small" lineHeight="condensed">
              {tz.format(currentAnnouncement.postedDate, 'date.formats.date_at_time')}
            </Text>
          </Flex.Item>
        )}
      </Flex>
    )
  }

  const renderCourseDetails = () => {
    if (showCourseDetails) {
      return renderWithButtons(
        <Heading level="h2">
          {canEdit ? (
            <Link href={courseUrl} isWithinText={false}>
              {courseName}
            </Link>
          ) : (
            courseName
          )}
        </Heading>
      )
    }
  }

  const renderAnnouncementContent = () => {
    if (currentAnnouncement.id === FAUX_ANNOUNCEMENT_ID) {
      return (
        <div style={{textAlign: 'center'}}>
          <Text data-testid="no-recent-announcements" color="secondary" size="large">
            {I18n.t('No recent announcements')}
          </Text>
          {canEdit && canReadAnnouncements && (
            <View as="div">
              <K5AddAnnouncementButton courseName={courseName} courseUrl={courseUrl} />
            </View>
          )}
        </div>
      )
    }

    return (
      <>
        <div
          className="user_content"
          /* html sanitized by server */
          dangerouslySetInnerHTML={{__html: apiUserContent.convert(currentAnnouncement.message)}}
        />
        {currentAnnouncement.attachment && (
          <Text size="small">
            <a
              href={currentAnnouncement.attachment.url}
              title={currentAnnouncement.attachment.filename}
              /* classes request download button and preview overlay in instructure.js's postprocessing */
              className="instructure_file_link preview_in_overlay"
              data-api-returntype="File"
            >
              {currentAnnouncement.attachment.display_name}
            </a>
          </Text>
        )}
      </>
    )
  }

  // if there are no announcements, show students nothing
  if (!canEdit && noAnnouncementsAtAll()) {
    return null
  }

  // if there are no announcements at all, show teachers something
  if (canEdit && noAnnouncementsAtAll()) {
    return (
      <EmptyK5Announcement
        courseUrl={courseUrl}
        courseName={courseName}
        canReadAnnouncements={canReadAnnouncements}
      />
    )
  }

  return (
    <View>
      {renderCourseDetails()}
      {fetchForNeededAnnouncementIsInFlight() ? (
        <K5AnnouncementLoadingMask notForHomeroom={!showCourseDetails} />
      ) : (
        <View>
          {!published && showCourseDetails && (
            <Text size="small">{I18n.t('Your homeroom is currently unpublished.')}</Text>
          )}
          {showCourseDetails
            ? renderAnnouncementTitle()
            : renderWithButtons(renderAnnouncementTitle())}
          {renderAnnouncementContent()}
        </View>
      )}

      <PresentationContent>
        <hr />
      </PresentationContent>
    </View>
  )
}

export const K5AnnouncementType = PropTypes.shape({
  id: PropTypes.string.isRequired,
  title: PropTypes.string,
  message: PropTypes.string.isRequired,
  url: PropTypes.string,
  postedDate: PropTypes.instanceOf(Date),
  attachment: PropTypes.shape({
    url: PropTypes.string.isRequired,
    filename: PropTypes.string.isRequired,
    display_name: PropTypes.string.isRequired,
  }),
})

K5Announcement.propTypes = {
  // course
  courseId: PropTypes.string,
  courseName: PropTypes.string,
  courseUrl: PropTypes.string,
  published: PropTypes.bool,
  canEdit: PropTypes.bool.isRequired,
  canReadAnnouncements: PropTypes.bool.isRequired,
  showCourseDetails: PropTypes.bool.isRequired,
  // announcement
  firstAnnouncement: K5AnnouncementType,
}
