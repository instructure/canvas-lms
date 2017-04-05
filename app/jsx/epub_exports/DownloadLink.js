import React from 'react'
import I18n from 'i18n!epub_exports'
import _ from 'underscore'

  var DownloadLink = React.createClass({
    displayName: 'DownloadLink',
    propTypes: {
      course: React.PropTypes.object.isRequired
    },

    epubExport () {
      return this.props.course.epub_export || {};
    },
    showDownloadLink () {
      return _.isObject(this.epubExport().permissions) &&
        this.epubExport().permissions.download;
    },

    //
    // Rendering
    //

    downloadLink (attachment, message) {
      if (_.isObject(attachment)) {
        return (
          <a href={attachment.url} className="icon-download">
            {message}
          </a>
        );
      } else {
        return null;
      };
    },

    render() {
      if (!this.showDownloadLink()) {
        return null;
      };

      return (
        <span>
          {this.downloadLink(this.epubExport().epub_attachment, I18n.t("Download ePub"))}
          {this.downloadLink(this.epubExport().zip_attachment, I18n.t("Download Associated Files"))}
        </span>
      );
    }
  });

export default DownloadLink
