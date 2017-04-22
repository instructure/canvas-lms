import React from 'react'
import classnames from 'classnames'
import CurrentUploads from 'compiled/react_files/components/CurrentUploads'
import UploadProgress from 'jsx/files/UploadProgress'

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

export default React.createClass(CurrentUploads)
