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

import React from 'react'
import I18n from 'i18n!k5_dashboard'
import tz from '@canvas/timezone'
import PropTypes from 'prop-types'

import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {View} from '@instructure/ui-view'
import {Flex} from '@instructure/ui-flex'
import {IconButton} from '@instructure/ui-buttons'
import {IconEditLine} from '@instructure/ui-icons'
import {Text} from '@instructure/ui-text'
import {PresentationContent} from '@instructure/ui-a11y-content'

import apiUserContent from '@canvas/util/jquery/apiUserContent'

export default function K5Announcement({
  title,
  message,
  url,
  courseName,
  courseUrl,
  canEdit,
  attachment,
  published,
  postedDate,
  showCourseDetails
}) {
  const renderWithEditButton = content => (
    <Flex alignItems="center" justifyItems="space-between" margin="medium 0 0">
      <Flex.Item>{content}</Flex.Item>
      {canEdit && (
        <Flex.Item>
          <IconButton
            screenReaderLabel={I18n.t('Edit announcement %{title}', {
              title
            })}
            withBackground={false}
            withBorder={false}
            href={`${url}/edit`}
          >
            <IconEditLine />
          </IconButton>
        </Flex.Item>
      )}
    </Flex>
  )

  const renderAnnouncementTitle = () => (
    <Heading level="h3" margin="x-small 0 0">
      {title}
    </Heading>
  )

  return (
    <View>
      {showCourseDetails &&
        renderWithEditButton(
          <Heading level="h3" as="h2">
            {canEdit ? (
              <Link href={courseUrl} isWithinText={false}>
                {courseName}
              </Link>
            ) : (
              courseName
            )}
          </Heading>
        )}
      <View>
        {!published && showCourseDetails && (
          <Text size="small">{I18n.t('Your homeroom is currently unpublished.')}</Text>
        )}
        {showCourseDetails
          ? renderAnnouncementTitle()
          : renderWithEditButton(renderAnnouncementTitle())}
        {postedDate && (
          <Text as="div" size="small" color="secondary">
            {I18n.t('Posted on %{date}', {
              date: tz.format(postedDate, 'date.formats.full_with_weekday')
            })}
          </Text>
        )}
        <div
          className="user_content"
          /* html sanitized by server */
          dangerouslySetInnerHTML={{__html: apiUserContent.convert(message)}}
        />
        {attachment && (
          <Text size="small">
            <a
              href={attachment.url}
              title={attachment.filename}
              /* classes request download button and preview overlay in instructure.js's postprocessing */
              className="instructure_file_link preview_in_overlay"
              data-api-returntype="File"
            >
              {attachment.display_name}
            </a>
          </Text>
        )}
      </View>

      <PresentationContent>
        <hr />
      </PresentationContent>
    </View>
  )
}

K5Announcement.propTypes = {
  courseName: PropTypes.string,
  courseUrl: PropTypes.string,
  canEdit: PropTypes.bool.isRequired,
  title: PropTypes.string.isRequired,
  message: PropTypes.node.isRequired,
  url: PropTypes.string.isRequired,
  attachment: PropTypes.object,
  published: PropTypes.bool,
  postedDate: PropTypes.string,
  showCourseDetails: PropTypes.bool.isRequired
}
