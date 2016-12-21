define([
  'react',
  'jsx/webzip_export/components/ExportListItem'
], (React, ExportListItem) => {
  class ExportList extends React.Component {
    static propTypes = {
      exports: React.PropTypes.arrayOf(React.PropTypes.shape({
        date: React.PropTypes.string.isRequired,
        link: React.PropTypes.string.isRequired,
      })).isRequired
    }

    renderExportListItems () {
      return this.props.exports.map((webzip, key) =>
        <ExportListItem key={key} link={webzip.link} date={webzip.date} />
      )
    }

    render () {
      return (
        <ul className={'webzipexport__list'}>
          {this.renderExportListItems()}
        </ul>
      )
    }
  }

  return ExportList
})
