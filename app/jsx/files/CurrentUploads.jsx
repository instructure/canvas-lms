/** @jsx React.DOM */

define([
  'react',
  'classnames',
  'compiled/react_files/components/CurrentUploads',
  'jsx/files/UploadProgress'
  ], function(React, classnames, CurrentUploads, UploadProgress) {

    CurrentUploads.renderUploadProgress = function () {
      if (this.state.currentUploads.length) {
        var progessComponents = this.state.currentUploads.map((uploader) => {
          return <UploadProgress uploader={uploader} key={uploader.getFileName()} />
        });
        return (
          <div className='current_uploads__uploaders'>
            {progessComponents}
          </div>
        );
      } else {
        return null;
      }
    };

    CurrentUploads.render = function () {
      var classes = classnames({
        'current_uploads': this.state.currentUploads.length
      });

      return (
        <div className={classes}>
          {this.renderUploadProgress()}
        </div>
      );
    };

    return React.createClass(CurrentUploads);

});