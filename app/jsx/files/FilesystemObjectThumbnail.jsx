define([
  'react',
  'compiled/models/Folder',
  'compiled/util/mimeClass',
  'compiled/react_files/components/FilesystemObjectThumbnail'
], function (React, Folder, mimeClass, FilesystemObjectThumbnail) {

  FilesystemObjectThumbnail.render = function () {
    var additionalClassName = this.props.className ? this.props.className : '';

    if (this.state.thumbnail_url) {
      return (
        < span
          className={`media-object ef-thumbnail FilesystemObjectThumbnail ${additionalClassName}`}
          style = { {backgroundImage: `url('${this.state.thumbnail_url}')`} }
        ></span>
      );
    } else {
      var thumbnailClassName = (this.props.model instanceof Folder) ? 'folder' : mimeClass(this.props.model.get('content-type'));
      return (
        < i
          className={`media-object ef-big-icon FilesystemObjectThumbnail mimeClass-${thumbnailClassName} ${additionalClassName}`}
        ></i>
      );
    }
  };

  return React.createClass(FilesystemObjectThumbnail);

});
