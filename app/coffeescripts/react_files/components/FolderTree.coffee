define [
  'react'
  'react-router'
  'compiled/views/FileBrowserView'
], (React, Router, FileBrowserView) ->

  FolderTree = React.createClass


    componentDidMount: ->
      rootFolder = @props.rootTillCurrentFolder[0]
      new FileBrowserView({
        onlyShowFolders: true,
        rootFoldersToShow: [rootFolder]
        onClick: @onClick
        href: @hrefFor
      }).render().$el.appendTo(@refs.FolderTreeHolder.getDOMNode())
      @expandTillCurrentFolder(@props)


    componentWillReceiveProps: (newProps) ->
      @expandTillCurrentFolder(newProps)


    onClick: (event, folder) ->
      event.preventDefault()
      Router.transitionTo (if folder.urlPath() then 'folder' else 'rootFolder'), contextType: @props.contextType, contextId: @props.contextId, splat: folder.urlPath()


    hrefFor: (folder) ->
      Router.makeHref (if folder.urlPath() then 'folder' else 'rootFolder'), contextType: @props.contextType, contextId: @props.contextId, splat: folder.urlPath()


    expandTillCurrentFolder: (props) ->
      expandFolder = (folderIndex) ->
        return unless folder = props.rootTillCurrentFolder[folderIndex]
        folder.expand(false, {onlyShowFolders: true}).then ->
          expandFolder(folderIndex + 1)
      expandFolder(0)


    render: ->
      React.DOM.div( {className:"ef-folder-list", ref: 'FolderTreeHolder'})