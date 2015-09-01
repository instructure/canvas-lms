define([
  'react',
  'jsx/files/FilesystemObjectThumbnail',
  'compiled/react_files/modules/customPropTypes'
], function (React, FilesystemObjectThumbnail, customPropTypes) {

  var MAX_THUMBNAILS_TO_SHOW = 10;

  var DragFeedback = React.createClass({
    displayName: 'DragFeedback',

    propTypes: {
      itemsToDrag: React.PropTypes.arrayOf(customPropTypes.filesystemObject).isRequired,
      pageX: React.PropTypes.number.isRequired,
      pageY: React.PropTypes.number.isRequired
    },

    render () {
      return (

        <div className='DragFeedback' style={{
          webkitTransform: `translate3d(${this.props.pageX + 6}px, ${this.props.pageY + 6}px, 0)`,
          transform: `translate3d(${this.props.pageX + 6}px, ${this.props.pageY + 6}px, 0)`
        }}>

        {this.props.itemsToDrag.slice(0, MAX_THUMBNAILS_TO_SHOW).map((model, index) => {
          return (
            <FilesystemObjectThumbnail
              model={model}
              key={model.id}
              style={{
                left: 10 + index * 5 - index,
                top: 10 + index * 5 - index
              }}
            />
          );
        })}
        <span className='badge badge-important'>{this.props.itemsToDrag.length}</span>

        </div>
      );
    }
  });

  return DragFeedback;
});
