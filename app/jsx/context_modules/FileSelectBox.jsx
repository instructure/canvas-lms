/** @jsx React.DOM */

define([
  'underscore',
  'old_unsupported_dont_use_react',
  'i18n!context_modules',
  './stores/FileStore',
  './stores/FolderStore',
  'compiled/util/natcompare',
  'compiled/str/splitAssetString'
], function(_, React, I18n, FileStore, FolderStore, natcompare, splitAssetString) {

  var FileSelectBox = React.createClass({
    displayName: 'FileSelectBox',

    propTypes: {
      contextString: React.PropTypes.string.isRequired
    },

    getInitialState () {
      return {
        folders: []
      }
    },

    componentWillMount () {
      // Get a decent url partial in order to create the store.
      var contextUrl = splitAssetString(this.props.contextString).join('/');

      // Create the stores, and add change listeners to them.
      this.fileStore = new FileStore(contextUrl);
      this.folderStore = new FolderStore(contextUrl);
      this.fileStore.addChangeListener( () => {
        this.setState({
          files: this.fileStore.getState().items
        })
      });
      this.folderStore.addChangeListener( () => {
        this.setState({
          folders: this.folderStore.getState().items
        })
      });

      // Fetch the data.
      this.fileStore.fetch({fetchAll: true});
      this.folderStore.fetch({fetchAll: true});

    },

    // Let's us know if the stores are still loading data.
    isLoading () {
      return (this.fileStore.getState().isLoading) || (this.folderStore.getState().isLoading);
    },

    createFolderFileTreeStructure () {
      var {folders, files} = this.state;

      // Put files into the right folders.
      var groupedFiles = _.groupBy(files, 'folder_id');
      for (var key in groupedFiles) {
        var folder = _.findWhere(folders, {id: parseInt(key, 10)});
        if (folder) {
          folder.files = groupedFiles[key];
        }
      }

      folders = folders.sort(function (a, b) {
        // Make sure we use a sane sorting mechanism.
        return natcompare.strings(a.full_name, b.full_name);
      });

      return folders;

    },

    renderFilesAndFolders () {
      var tree = this.createFolderFileTreeStructure();

      if (this.isLoading()) {
        return <option>{I18n.t('Loading...')}</option>
      }

      var renderFiles = function (folder) {
        return folder.files.map( (file) => {
          return (<option key={'file-' + file.id} value={file.id}>{file.display_name}</option>);
        });
      }

      return tree.map( (folder) => {
        if (folder.files) {
          return (
            <optgroup key={'folder-' + folder.id} label={folder.full_name}>
              {renderFiles(folder)}
            </optgroup>
          );
        }

      });
    },

    render () {
      return (
        <div>
          <select ref="selectBox" aria-busy={this.isLoading()} className="module_item_select" aria-label={I18n.t('Select the file you want to associate, or add a file by selecting "New File".')} multiple>
            <option value="new">{I18n.t('[ New File ]')}</option>
            {this.renderFilesAndFolders()}
          </select>
        </div>
      );
    }
  });

  return FileSelectBox;

});