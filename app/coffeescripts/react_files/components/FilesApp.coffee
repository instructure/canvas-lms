define [
  'underscore'
  'react'
  '../utils/withGlobalDom'
  'compiled/models/Folder'
  './Toolbar'
  './Breadcrumbs'
  './FolderTree'
  './FilesUsage'
  './FolderChildren'
  './SearchResults'
], (_, React, withGlobalDom, Folder, Toolbar, Breadcrumbs, FolderTree, FilesUsage, FolderChildren, SearchResults) ->

  FilesApp = React.createClass

    propTypes:
      currentFolder: React.PropTypes.instanceOf(Folder).isRequired

    render: withGlobalDom ->
      div null,
        Toolbar(baseUrl: @props.baseUrl)
        (Breadcrumbs(baseUrl: @props.baseUrl, folderPath:@props.folderPath) if @props.showBreadcrumb)
        div className: 'ef-main',
          aside className: 'visible-desktop ef-folder-content',
            FolderTree()
            FilesUsage(contextType:@props.contextType, contextId:@props.contextId)
          if @props.currentFolder
            FolderChildren(model: @props.currentFolder, baseUrl: @props.baseUrl)
          else
            SearchResults(collection: @props.searchResults)




