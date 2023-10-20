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
import NoResultsDesert from '../images/NoResultsDesert.svg'
import {Text} from '@instructure/ui-text'
import AnnouncementsPagination from './AnnouncementPagination'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('past_global_announcements')

const AnnouncementFactory = (announcements, section) => {
  const styles = {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
  }

  switch (announcements.length) {
    case 0:
      return (
        <div style={styles}>
          <img
            data-testid={`NoGlobalAnnouncementImage${section}`}
            alt=""
            src={NoResultsDesert}
            style={{width: '400px'}}
          />
          <Text size="large">{I18n.t('No announcements to display')}</Text>
        </div>
      )
    case 1:
      return <div dangerouslySetInnerHTML={{__html: announcements[0]}} />
    default:
      return <AnnouncementsPagination announcements={announcements} section={section} />
  }
}

export default AnnouncementFactory
