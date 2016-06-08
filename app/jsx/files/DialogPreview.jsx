define([
  'i18n!react_files',
  'react',
  'compiled/react_files/modules/customPropTypes',
  'compiled/models/Folder',
  'compiled/react_files/modules/filesEnv',
  'jsx/files/FilesystemObjectThumbnail'

  ], function(I18n, React, customPropTypes, Folder, filesEnv, FilesystemObjectThumbnail) {

  var MAX_THUMBNAILS_TO_SHOW = 5;

  // This is used to show a preview inside of a modal dialog.
  var DialogPreview = React.createClass({
    displayName: 'DialogPreview',

    propTypes: {
      itemsToShow: React.PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired
    },

    renderPreview () {
      if (this.props.itemsToShow.length === 1) {
        return (
          <FilesystemObjectThumbnail
            model={this.props.itemsToShow[0]}
            className='DialogPreview__thumbnail'
          />
        );
      } else {
        return this.props.itemsToShow.slice(0, MAX_THUMBNAILS_TO_SHOW).map((model, index) => {
          return (
            <i
              key={model.cid}
              className='media-object ef-big-icon FilesystemObjectThumbnail mimeClass-file DialogPreview__thumbnail'
              style={{
                left: (10 * index),
                top: (-140 * index)
              }}
            />
          );
        });
      }
    },

    render () {
      return (
        <div className='DialogPreview__container'>
          {this.renderPreview()}
        </div>
      );
    }
  });

  return DialogPreview;

});
