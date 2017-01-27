import React from 'react'
import Folder from 'compiled/models/Folder'
import mimeClass from 'compiled/util/mimeClass'
import FilesystemObjectThumbnail from 'compiled/react_files/components/FilesystemObjectThumbnail'

  FilesystemObjectThumbnail.render = function () {
    var additionalClassName = this.props.className ? this.props.className : '';

    if (this.state.thumbnail_url) {
      return (
        <span
          className={`media-object ef-thumbnail FilesystemObjectThumbnail ${additionalClassName}`}
          style = { {backgroundImage: `url('${this.state.thumbnail_url}')`} }
        ></span>
      );
    } else {
      var thumbnailClassName = (this.props.model instanceof Folder) ?
        (this.props.model.get('for_submissions') ? 'folder-locked' : 'folder') :
        mimeClass(this.props.model.get('content-type'));
      return (
        <i
          className={`media-object ef-big-icon FilesystemObjectThumbnail mimeClass-${thumbnailClassName} ${additionalClassName}`}
        ></i>
      );
    }
  };

export default React.createClass(FilesystemObjectThumbnail)
