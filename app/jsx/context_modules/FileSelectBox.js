/*
 * Copyright (C) 2015 - present Instructure, Inc.
 *
 * This file is part of Canvas.
 *
 * Canvas is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation, version 3 of the License.
 *
 * Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
 * A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
 * details.
 *
 * You should have received a copy of the GNU Affero General Public License along
 * with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import _ from 'underscore'
import React from 'react'
import PropTypes from 'prop-types'
import I18n from 'i18n!context_modules'
import FileStore from './stores/FileStore'
import FolderStore from './stores/FolderStore'
import natcompare from 'compiled/util/natcompare'
import splitAssetString from 'compiled/str/splitAssetString'

  var FileSelectBox = React.createClass({
    displayName: 'FileSelectBox',

    propTypes: {
      contextString: PropTypes.string.isRequired
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
      this.fileStore = new FileStore(contextUrl, {perPage: 50, only: ['names']});
      this.folderStore = new FolderStore(contextUrl, {perPage: 50});
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

export default FileSelectBox
