define [
  'jquery'
  'i18n!folder_tree'
  'react'
  'react-dom'
  '../modules/BBTreeBrowserView'
  'compiled/views/RootFoldersFinder'
  '../modules/customPropTypes'
  'compiled/react_files/modules/filesEnv',
  'page',
  'compiled/jquery.rails_flash_notifications'
], ($, I18n, React, ReactDOM, BBTreeBrowserView, RootFoldersFinder, customPropTypes, filesEnv, page) ->

  FolderTree =
    displayName: 'FolderTree'

    propTypes:
      rootFoldersToShow: React.PropTypes.arrayOf(customPropTypes.folder).isRequired
      rootTillCurrentFolder: React.PropTypes.arrayOf(customPropTypes.folder)

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
          element: ReactDOM.findDOMNode(@refs.FolderTreeHolder)
        }).index

      @expandTillCurrentFolder(@props)

    componentWillUnmount: ->
      BBTreeBrowserView.remove(@treeBrowserViewId)

    componentWillReceiveProps: (newProps) ->
      @expandTillCurrentFolder(newProps)

    onClick: (event, folder) ->
      event.preventDefault()
      $(ReactDOM.findDOMNode(@refs.FolderTreeHolder)).find('.' + @focusStyleClass).each( (key, value) => $(value).removeClass(@focusStyleClass))
      $(ReactDOM.findDOMNode(@refs.FolderTreeHolder)).find('.' + @selectedStyleClass).each( (key, value) => $(value).removeClass(@selectedStyleClass))
      if folder.get('locked_for_user')
        message = I18n.t('This folder is currently locked and unavailable to view.')
        $.flashError message
        $.screenReaderFlashMessage message
      else
        $.screenReaderFlashMessageExclusive I18n.t('File list updated')
        page("#{filesEnv.baseUrl}/folder/#{folder.urlPath()}");



    hrefFor: (folder) ->
      # @makeHref (if folder.urlPath() then 'folder' else 'rootFolder'), splat: folder.urlPath()



    focusStyleClass: 'FolderTree__folderItem--focused'
    selectedStyleClass: 'FolderTree__folderItem--selected'


    expandTillCurrentFolder: (props) ->
      expandFolder = (folderIndex) ->
        return unless folder = props.rootTillCurrentFolder?[folderIndex]
        folder.expand(false, {onlyShowSubtrees: true}).then ->
          expandFolder(folderIndex + 1)
      expandFolder(0)
