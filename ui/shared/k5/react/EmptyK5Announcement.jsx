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

import {useScope as useI18nScope} from '@canvas/i18n'
import React from 'react'
import {string, bool} from 'prop-types'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import {AccessibleContent, PresentationContent} from '@instructure/ui-a11y-content'

const I18n = useI18nScope('empty_homeroom_announcement')

export const K5AddAnnouncementButton = ({courseUrl, courseName}) => {
  return (
    <Button
      renderIcon={IconAddLine}
      margin="small 0"
      href={`${courseUrl}/discussion_topics/new?is_announcement=true`}
    >
      <AccessibleContent alt={I18n.t('Create a new announcement for %{courseName}', {courseName})}>
        {I18n.t('Announcement')}
      </AccessibleContent>
    </Button>
  )
}
K5AddAnnouncementButton.propTypes = {
  courseUrl: string.isRequired,
  courseName: string.isRequired,
}

export default function EmptyK5Announcement({courseUrl, courseName, canReadAnnouncements}) {
  return (
    <View>
      <Heading level="h3" as="h2" margin="medium 0 small">
        <Link href={courseUrl} isWithinText={false}>
          {courseName}
        </Link>
      </Heading>
      <Text as="div">
        {canReadAnnouncements
          ? I18n.t('New announcements show up in this area. Create a new announcement now.')
          : I18n.t('You do not have permission to view announcements in this course.')}
      </Text>
      {canReadAnnouncements && (
        <K5AddAnnouncementButton courseUrl={courseUrl} courseName={courseName} />
      )}
      <PresentationContent>
        <hr />
      </PresentationContent>
    </View>
  )
}

EmptyK5Announcement.propTypes = {
  courseUrl: string.isRequired,
  courseName: string.isRequired,
  canReadAnnouncements: bool.isRequired,
}
