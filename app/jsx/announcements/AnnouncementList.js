/*
 * Copyright (C) 2016 - present Instructure, Inc.
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
import PropTypes from 'prop-types'
import I18n from 'i18n!announcements'
import FriendlyDatetime from '../shared/FriendlyDatetime'
import ToggleDetails from 'instructure-ui/lib/components/ToggleDetails'
import Table from 'instructure-ui/lib/components/Table'
import Link from 'instructure-ui/lib/components/Link'
import TextHelper from 'compiled/str/TextHelper'
import $ from 'jquery'
import 'jquery.instructure_date_and_time'

export default class AnnouncementList extends React.Component {

    static propTypes = {
      announcements: PropTypes.arrayOf(
        PropTypes.shape({
          id: PropTypes.number.isRequired,
          title: PropTypes.string.isRequired,
          message: PropTypes.string.isRequired,
          posted_at: PropTypes.string.isRequired,
          url: PropTypes.string.isRequired,
          pinned: PropTypes.bool.isRequired
        })
      )
    }

    static defaultProps = {
      announcements: []
    }

    renderAnnouncement () {
      return this.props.announcements.map(c => (
        <tr key={c.id} className={c.pinned ? "AnnouncementList__pinned" : ""}>
          <td>
            <ToggleDetails summary={TextHelper.truncateText(c.title, { max: 100 })} className="AnnouncementList__message">
              <p dangerouslySetInnerHTML={{__html: c.message}}/>
              <Link href={c.url}>{I18n.t('View Announcement')}</Link>
            </ToggleDetails>
          </td>
          <td className="AnnouncementList__posted-at">
            { I18n.t('%{posted_at}', { posted_at: $.datetimeString(c.posted_at) }) }
          </td>
        </tr>
      ))
    }

    renderTable () {
      if (this.props.announcements.length) {
        return (
          <Table caption={I18n.t('Active Announcements')} striped="rows">
            <tbody>
              {this.renderAnnouncement()}
            </tbody>
          </Table>
        )
      }
      return null;
    }

    render () {
      return (
        <div className="AnnouncementList">
          {this.renderTable()}
        </div>
      )
    }
  }
