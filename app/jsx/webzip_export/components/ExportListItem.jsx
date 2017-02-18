define([
  'react',
  'i18n!webzip_exports',
  'jquery',
  'jquery.instructure_date_and_time'
], (React, I18n, $) => {
  class ExportListItem extends React.Component {
    static propTypes = {
      date: React.PropTypes.string.isRequired,
      link: React.PropTypes.string.isRequired,
      workflowState: React.PropTypes.string.isRequired,
      newExport: React.PropTypes.bool.isRequired
    }

    render () {
      let text = <span>{I18n.t('Package export from')}</span>
      let body = <a href={this.props.link}>{$.datetimeString(this.props.date)}</a>
      if (this.props.newExport && this.props.workflowState === 'generated') {
        text = <span>{I18n.t('Most recent export')}</span>
      } else if (this.props.newExport && this.props.workflowState === 'failed') {
        text = <span className="text-error">{I18n.t('Export failed')}</span>
        body = $.datetimeString(this.props.date)
      }
      return (
        <li className="webzipexport__list__item">
          {text}
          <span>: {body}</span>
        </li>
      )
    }
  }

  return ExportListItem
})

