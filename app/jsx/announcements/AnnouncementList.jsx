define([
  'react',
  'i18n!announcements',
  'jsx/shared/FriendlyDatetime',
  'instructure-ui/ToggleDetails',
  'instructure-ui/Table',
  'instructure-ui/Link',
  'compiled/str/TextHelper',
  'jquery',
  'jquery.instructure_date_and_time'
], (React, I18n, FriendlyDatetime, { default: ToggleDetails }, { default: Table }, { default: Link }, TextHelper, $) => {
  class AnnouncementList extends React.Component {

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

  return AnnouncementList
})
