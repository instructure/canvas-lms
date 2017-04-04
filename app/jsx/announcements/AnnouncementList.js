import React from 'react'
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
      announcements: React.PropTypes.arrayOf(
        React.PropTypes.shape({
          id: React.PropTypes.number.isRequired,
          title: React.PropTypes.string.isRequired,
          message: React.PropTypes.string.isRequired,
          posted_at: React.PropTypes.string.isRequired,
          url: React.PropTypes.string.isRequired
        })
      )
    }

    static defaultProps = {
      announcements: []
    }

    renderAnnouncement () {
      return this.props.announcements.map(c => (
        <tr key={c.id}>
          <td>
            <ToggleDetails summary={TextHelper.truncateText(c.title, { max: 100 })} className="AnnouncementList__message">
              <p>{TextHelper.truncateText(c.message, { max: 200 })}</p>
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
          <Table caption={I18n.t('Recent Announcements')} striped="rows">
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
