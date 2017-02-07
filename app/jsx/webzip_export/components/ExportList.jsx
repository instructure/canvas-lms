define([
  'react',
  'jsx/webzip_export/components/ExportListItem'
], (React, ExportListItem) => {
  class ExportList extends React.Component {
    static propTypes = {
      exports: React.PropTypes.array.isRequired
    }

    renderExportListItems () {
      return this.props.exports.map(function (webzip, key) {
        return <ExportListItem key={key} link={webzip.link} date={webzip.date} />
      })
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
