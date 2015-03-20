define [
  'jquery'
  'i18n!folder_tree'
  'react'
  'react-router'
  '../modules/BBTreeBrowserView'
  'compiled/views/RootFoldersFinder'
  '../modules/customPropTypes'
  'compiled/react/shared/utils/withReactElement'
  'compiled/jquery.rails_flash_notifications'
], ($, I18n, React, Router, BBTreeBrowserView, RootFoldersFinder, customPropTypes, withReactElement) ->

  FolderTree = React.createClass
    displayName: 'FolderTree'

    propTypes:
      rootFoldersToShow: React.PropTypes.arrayOf(customPropTypes.folder).isRequired
      rootTillCurrentFolder: React.PropTypes.arrayOf(customPropTypes.folder)

    mixins: [Router.Navigation, Router.State]

    componentDidMount: ->
      rootFoldersFinder = new RootFoldersFinder({
        rootFoldersToShow: @props.rootFoldersToShow
      })

      @treeBrowserId = BBTreeBrowserView.create({
          onlyShowSubtrees: true,
          rootModelsFinder: rootFoldersFinder
          onClick: @onClick
          dndOptions: @props.dndOptions
          href: @hrefFor
          focusStyleClass: @focusStyleClass
          selectedStyleClass: @selectedStyleClass
          autoFetch: true
          fetchItAll: "to heck"
        },
        {
          render: true
          element: @refs.FolderTreeHolder.getDOMNode()
        }).index

      @expandTillCurrentFolder(@props)

    componentWillUnmount: ->
      BBTreeBrowserView.remove(@treeBrowserViewId)

    componentWillReceiveProps: (newProps) ->
      @expandTillCurrentFolder(newProps)

    onClick: (event, folder) ->
      event.preventDefault()
      $(@refs.FolderTreeHolder.getDOMNode()).find('.' + @focusStyleClass).each( (key, value) => $(value).removeClass(@focusStyleClass))
      $(@refs.FolderTreeHolder.getDOMNode()).find('.' + @selectedStyleClass).each( (key, value) => $(value).removeClass(@selectedStyleClass))
      if folder.get('locked_for_user')
        message = I18n.t('This folder is currently locked and unavailable to view.')
        $.flashError message
        $.screenReaderFlashMessage message
      else
        $.screenReaderFlashMessageExclusive I18n.t('File list updated')
        @transitionTo (if folder.urlPath() then 'folder' else 'rootFolder'), splat: folder.urlPath()



    hrefFor: (folder) ->
      @makeHref (if folder.urlPath() then 'folder' else 'rootFolder'), splat: folder.urlPath()



    focusStyleClass: 'FolderTree__folderItem--focused'
    selectedStyleClass: 'FolderTree__folderItem--selected'


    expandTillCurrentFolder: (props) ->
      expandFolder = (folderIndex) ->
        return unless folder = props.rootTillCurrentFolder?[folderIndex]
        folder.expand(false, {onlyShowSubtrees: true}).then ->
          expandFolder(folderIndex + 1)
      expandFolder(0)


    render: withReactElement ->
      div( {className:"ef-folder-list", ref: 'FolderTreeHolder'})
