define([
  'react',
  'i18n!epub_exports',
  'underscore'
], function(React, I18n, _){

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

    render() {
      var url;

      if (!this.showDownloadLink())
        return null;

      if (_.isObject(this.epubExport().attachment)) {
        url = this.epubExport().attachment.url;
      };

      return (
        <a href={url} className="icon-download">
          {I18n.t("Download")}
        </a>
      );
    }
  });

  return DownloadLink;
});
