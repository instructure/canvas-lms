#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'react'
  'underscore'
  'i18n!react_files'
  'compiled/str/splitAssetString'
  'jsx/files/Toolbar'
  'jsx/files/FolderTree'
  'jsx/files/FilesUsage'
  '../mixins/MultiselectableMixin'
  '../mixins/dndMixin'
  '../modules/filesEnv'
], (React, _, I18n, splitAssetString, Toolbar, FolderTree, FilesUsage, MultiselectableMixin, dndMixin, filesEnv) ->


  FilesApp =
    displayName: 'FilesApp'

    onResolvePath: ({currentFolder, rootTillCurrentFolder, showingSearchResults, searchResultCollection}) ->
      updatedModels = @state.updatedModels

      if currentFolder && !showingSearchResults
        updatedModels.forEach (model, index, models) ->
          if currentFolder.id.toString() isnt model.get("folder_id") and
             removedModel = currentFolder.files.findWhere({id: model.get("id")})
            currentFolder.files.remove removedModel
            models.splice(index, 1)

      @setState
        currentFolder: currentFolder
        rootTillCurrentFolder: rootTillCurrentFolder
        showingSearchResults: showingSearchResults
        selectedItems: []
        searchResultCollection: searchResultCollection
        updatedModels: updatedModels

    getInitialState: ->
      {
        updatedModels: []
        currentFolder: null
        rootTillCurrentFolder: null
        showingSearchResults: false
        showingModal: false
        modalContents: null  # This should be a React Component to render in the modal container.
      }

    mixins: [MultiselectableMixin, dndMixin]

    # for MultiselectableMixin
    selectables: ->
      if @state.showingSearchResults
        @state.searchResultCollection.models
      else
        @state.currentFolder.children(@props.query)

    onMove: (modelsToMove) ->
      updatedModels = _.uniq(@state.updatedModels.concat(modelsToMove), "id")
      @setState {updatedModels}

    getPreviewQuery: ->
      retObj =
        preview: @state.selectedItems[0]?.id or true
      if @state.selectedItems.length > 1
        retObj.only_preview = @state.selectedItems.map((item) -> item.id).join(',')
      if @props.query?.search_term
        retObj.search_term = @props.query.search_term
      if @props.query?.sort
        retObj.sort = @props.query.sort
      if @props.query?.order
        retObj.order = @props.query.order
      retObj

    openModal: (contents, afterClose) ->
      @setState
        modalContents: contents
        showingModal: true
        afterModalClose: afterClose

    closeModal: ->
      @setState(showingModal: false, -> @state.afterModalClose())
