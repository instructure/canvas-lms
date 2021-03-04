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

import I18n from 'i18n!k5_dashboard'
import React from 'react'
import {string} from 'prop-types'
import {View} from '@instructure/ui-view'
import {Heading} from '@instructure/ui-heading'
import {Link} from '@instructure/ui-link'
import {Text} from '@instructure/ui-text'
import {Button} from '@instructure/ui-buttons'
import {IconAddLine} from '@instructure/ui-icons'
import {AccessibleContent, PresentationContent} from '@instructure/ui-a11y-content'

export default function EmptyHomeroomAnnouncement({courseUrl, courseName}) {
  return (
    <View>
      <Heading level="h3" as="h2" margin="small 0">
        <Link href={courseUrl} isWithinText={false}>
          {courseName}
        </Link>
      </Heading>
      <Text as="div">
        {I18n.t('Every new announcement shows up in this area. Create your first one now.')}
      </Text>
      <Button
        renderIcon={IconAddLine}
        margin="small 0"
        href={`${courseUrl}/discussion_topics/new?is_announcement=true`}
      >
        <AccessibleContent
          alt={I18n.t('Create a new announcement for %{courseName}', {courseName})}
        >
          {I18n.t('Announcement')}
        </AccessibleContent>
      </Button>
      <PresentationContent>
        <hr />
      </PresentationContent>
    </View>
  )
}

EmptyHomeroomAnnouncement.propTypes = {
  courseUrl: string.isRequired,
  courseName: string.isRequired
}
