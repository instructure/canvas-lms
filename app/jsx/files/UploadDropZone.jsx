define([
  'underscore',
  'react',
  'react-dom',
  'jquery',
  'i18n!upload_drop_zone',
  'compiled/react_files/modules/FileOptionsCollection',
  'compiled/models/Folder',
  'compiled/jquery.rails_flash_notifications'
], function(_, React, ReactDOM, $, I18n, FileOptionsCollection, Folder) {

    var UploadDropZone = React.createClass({
      displayName: 'UploadDropZone',
      propTypes: {
        currentFolder: React.PropTypes.instanceOf(Folder)
      },
      getInitialState: function () {
        return ({active: false});
      },
      componentDidMount: function() {
        this.getParent().addEventListener('dragenter', this.onParentDragEnter);
        document.addEventListener('dragenter', this.killWindowDropDisplay);
        document.addEventListener('dragover', this.killWindowDropDisplay);
        document.addEventListener('drop', this.killWindowDrop);
      },

      componentWillUnmount: function() {
        this.getParent().removeEventListener('dragenter', this.onParentDragEnter);
        document.removeEventListener('dragenter', this.killWindowDropDisplay);
        document.removeEventListener('dragover', this.killWindowDropDisplay);
        document.removeEventListener('drop', this.killWindowDrop);
      },
      onDragEnter: function (e) {
        if (this.shouldAcceptDrop(e.dataTransfer)) {
          this.setState({active: true});
          e.dataTransfer.dropEffect = 'copy';
          e.preventDefault();
          e.stopPropagation(); // keep event from getting to document
          return false;
        } else {
          return true;
        }
      },
      onDragLeave: function (e) {
        this.setState({active: false});
      },
      onDrop: function (e) {
        this.setState({active: false});
        FileOptionsCollection.setFolder(this.props.currentFolder);
        FileOptionsCollection.setOptionsFromFiles(e.dataTransfer.files, true);
        e.preventDefault();
        e.stopPropagation();
        return false;
      },

      /* when you drag a file over the parent, make drop zone active
      # remainder of drag-n-drop events happen on dropzone
      */
      onParentDragEnter: function (e) {
        if (this.shouldAcceptDrop(e.dataTransfer)) {
          if (!this.state.active) {
            this.setState({active: true});
          }
        }
      },

      killWindowDropDisplay: function (e) {
        if (e.target != this.getParent()) {
          e.preventDefault();
        }
      },

      killWindowDrop: function (e) {
        e.preventDefault();
      },

      shouldAcceptDrop: function (dataTransfer) {
        if (dataTransfer) {
          return (_.indexOf(dataTransfer.types, 'Files') >= 0);
        }
      },

      getParent: function () {
        // We are actually returning the parent's parent here because that
        // gives a much more consistently sized container to start displaying
        // the drop zone overlay with.
        return ReactDOM.findDOMNode(this).parentElement.parentElement;
      },

      buildNonActiveDropZone: function () {
        return (<div className='UploadDropZone'></div>);
      },

      buildInstructions: function () {
        return (
          <div className='UploadDropZone__instructions'>
            <i className='icon-upload UploadDropZone__instructions--icon-upload' />
            <div>
              <p className='UploadDropZone__instructions--drag'>
                { I18n.t('drop_to_upload', 'Drop items to upload') }
              </p>
            </div>
          </div>
        );
      },

      buildDropZone: function () {
        return (
          <div className='UploadDropZone UploadDropZone__active'
             onDrop = { this.onDrop }
             onDragLeave = { this.onDragLeave }
             onDragOver = { this.onDragEnter }
             onDragEnter = { this.onDragEnter }
          >
            {this.buildInstructions() }
          </div>
        );
      },

      render: function () {
        if (this.state.active) {
          return this.buildDropZone();
        } else {
          return this.buildNonActiveDropZone();
        }
      }

    });

    return UploadDropZone;
});
