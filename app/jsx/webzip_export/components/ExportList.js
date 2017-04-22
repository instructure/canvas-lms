import React from 'react'
import I18n from 'i18n!webzip_exports'
import ExportListItem from 'jsx/webzip_export/components/ExportListItem'
  class ExportList extends React.Component {
    static propTypes = {
      exports: React.PropTypes.arrayOf(React.PropTypes.shape({
        date: React.PropTypes.string.isRequired,
        link: React.PropTypes.string,
        workflowState: React.PropTypes.string.isRequired,
        newExport: React.PropTypes.bool.isRequired
      })).isRequired
    }

    renderExportListItems () {
      return this.props.exports.map((webzip, key) => (
        <ExportListItem
          key={key}
          link={webzip.link}
          date={webzip.date}
          workflowState={webzip.workflowState}
          newExport={webzip.newExport}
        />
      ))
    }

    render () {
      if (this.props.exports.length === 0) {
        return (
          <p className="webzipexport__list">
            {I18n.t('No exports to display')}
          </p>
        )
      }
      return (
        <ul className="webzipexport__list">
          {this.renderExportListItems()}
        </ul>
      )
    }
  }

export default ExportList
