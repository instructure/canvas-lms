/** @jsx React.DOM */
define(function(require) {
  var React = require('../../ext/react');
  var Essay = require('jsx!./essay');
  var I18n = require('i18n!quiz_statistics');

  var FileUpload = React.createClass({
    render: Essay.type.prototype.render,
    renderLinkButton: function() {
      return (
        <a className="btn" href={this.props.quizSubmissionsZipUrl} target="_blank" style={{marginBottom: "20px", maxWidth: "50%"}}>
          {I18n.t('download_submissions', 'Download All Files')}
        </a>
      );
    }
  });

  return FileUpload;
});