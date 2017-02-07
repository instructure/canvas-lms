define([
  'react',
  'underscore',
  'jsx/shared/ApiProgressBar',
  'i18n!webzip_exports',
], (React, _, ApiProgressBar, I18n) => {
  class ExportListItem extends React.Component {
    static propTypes = {
      date: React.PropTypes.string.isRequired,
      link: React.PropTypes.string.isRequired
    }

    render () {
      return (
        <li className={'webzipexport__list__item'}>
          <span>{I18n.t('Course Content Download from')}</span>
          <span>: <a href={this.props.link}>{this.props.date}</a></span>
        </li>
      )
    }
  }

  return ExportListItem
})

