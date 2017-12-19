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
  'jquery'
  'i18n!folder_tree'
  'react'
  'react-dom'
  'prop-types'
  '../modules/BBTreeBrowserView'
  '../../views/RootFoldersFinder'
  '../modules/customPropTypes'
  '../../react_files/modules/filesEnv',
  'page',
  '../../jquery.rails_flash_notifications'
], ($, I18n, React, ReactDOM, PropTypes, BBTreeBrowserView, RootFoldersFinder, customPropTypes, filesEnv, page) ->

  FolderTree =
    displayName: 'FolderTree'

    propTypes:
      rootFoldersToShow: PropTypes.arrayOf(customPropTypes.folder).isRequired
      rootTillCurrentFolder: PropTypes.arrayOf(customPropTypes.folder)

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
        page("#{filesEnv.baseUrl}/folder/#{folder.urlPath()}")



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
