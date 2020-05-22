/*
 * Copyright (C) 2020 - present Instructure, Inc.
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
import {Heading} from '@instructure/ui-heading/lib/Heading'
import {Text} from '@instructure/ui-text/lib/Text'
import I18n from 'i18n!past_global_announcements'
import NoResultsDesert from './SVG/NoResultsDesert.svg'

const PastGlobalAnnouncements = () => {
  let activeAnnouncements = (
    <div dangerouslySetInnerHTML={{__html: ENV.global_notifications.active}} />
  )

  let pastAnnouncements = <div dangerouslySetInnerHTML={{__html: ENV.global_notifications.past}} />

  const styles = {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center'
  }

  if (ENV.global_notifications.active === ' ') {
    activeAnnouncements = (
      <div style={styles}>
        <img
          data-testid="NoGlobalAnnouncementImageActive"
          alt=""
          src={NoResultsDesert}
          style={{width: '400px'}}
        />
        <Text size="large">{I18n.t('No announcements to display')}</Text>
      </div>
    )
  }

  if (ENV.global_notifications.past === ' ') {
    pastAnnouncements = (
      <div style={styles}>
        <img
          data-testid="NoGlobalAnnouncementImagePast"
          alt=""
          src={NoResultsDesert}
          style={{width: '400px'}}
        />
        <Text size="large">{I18n.t('No announcements to display')}</Text>
      </div>
    )
  }

  return (
    <>
      <Heading border="bottom" margin="medium">
        {I18n.t('Current')}
      </Heading>
      {activeAnnouncements}

      <Heading border="bottom" margin="medium">
        {I18n.t('Past')}
      </Heading>
      {pastAnnouncements}
    </>
  )
}

export default PastGlobalAnnouncements
