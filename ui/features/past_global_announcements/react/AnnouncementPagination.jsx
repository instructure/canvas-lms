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
import {Pagination} from '@instructure/ui-pagination'
import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('past_global_announcements')

/*
 * The account_notifications_controller#render_past_global_announcements
 * returns all announcements in an array of html strings. Each string
 * contains 5 announcements. All announcements are fetched
 * on initialization. This isn't true paging but paging was implemented
 * to enhance the user experience.
 */
export default class AnnouncementPagination extends React.Component {
  state = {
    currentPage: 0,
  }

  render() {
    const pages = this.props.announcements.map((v, i) => (
      <Pagination.Page
        key={btoa(`global_announcement_${this.props.section}_${i}`)}
        onClick={() => this.setState({currentPage: i})}
        current={i === this.state.currentPage}
      >
        {i + 1}
      </Pagination.Page>
    ))
    return (
      <>
        <div dangerouslySetInnerHTML={{__html: this.props.announcements[this.state.currentPage]}} />
        <Pagination
          as="nav"
          margin="small"
          variant="compact"
          labelNext={I18n.t('Next Page')}
          labelPrev={I18n.t('Previous Page')}
        >
          {pages}
        </Pagination>
      </>
    )
  }
}
