/*
 * Copyright (C) 2014 - present Instructure, Inc.
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

import $ from 'jquery'
import {useScope as useI18nScope} from '@canvas/i18n'
import ReactDOM from 'react-dom'
import PropTypes from 'prop-types'
import BBTreeBrowserView from '../modules/BBTreeBrowserView'
import RootFoldersFinder from '../../../RootFoldersFinder'
import customPropTypes from '@canvas/files/react/modules/customPropTypes'
import filesEnv from '@canvas/files/react/modules/filesEnv'
import page from 'page'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('folder_tree')

export default {
  displayName: 'FolderTree',

  propTypes: {
    rootFoldersToShow: PropTypes.arrayOf(customPropTypes.folder).isRequired,
    rootTillCurrentFolder: PropTypes.arrayOf(customPropTypes.folder),
  },

  componentDidMount() {
    const rootFoldersFinder = new RootFoldersFinder({
      rootFoldersToShow: this.props.rootFoldersToShow,
    })

    this.treeBrowserId = BBTreeBrowserView.create(
      {
        onlyShowSubtrees: true,
        rootModelsFinder: rootFoldersFinder,
        onClick: this.onClick,
        dndOptions: this.props.dndOptions,
        href: this.hrefFor,
        focusStyleClass: this.focusStyleClass,
        selectedStyleClass: this.selectedStyleClass,
        autoFetch: true,
        fetchItAll: 'to heck',
      },
      {
        render: true,
        element: ReactDOM.findDOMNode(this.refs.FolderTreeHolder),
      }
    ).index

    this.expandTillCurrentFolder(this.props)
  },

  componentWillUnmount() {
    BBTreeBrowserView.remove(this.treeBrowserViewId)
  },

  UNSAFE_componentWillReceiveProps(newProps) {
    this.expandTillCurrentFolder(newProps)
  },

  onClick(event, folder) {
    event.preventDefault()
    $(ReactDOM.findDOMNode(this.refs.FolderTreeHolder))
      .find(`.${this.focusStyleClass}`)
      .each((key, value) => $(value).removeClass(this.focusStyleClass))
    $(ReactDOM.findDOMNode(this.refs.FolderTreeHolder))
      .find(`.${this.selectedStyleClass}`)
      .each((key, value) => $(value).removeClass(this.selectedStyleClass))
    if (folder.get('locked_for_user')) {
      const message = I18n.t('This folder is currently locked and unavailable to view.')
      $.flashError(message)
      $.screenReaderFlashMessage(message)
    } else {
      $.screenReaderFlashMessageExclusive(I18n.t('File list updated'))
      page(`${filesEnv.baseUrl}/folder/${folder.urlPath()}`)
    }
  },

  hrefFor(_folder) {},
  // @makeHref (if folder.urlPath() then 'folder' else 'rootFolder'), splat: folder.urlPath()

  focusStyleClass: 'FolderTree__folderItem--focused',
  selectedStyleClass: 'FolderTree__folderItem--selected',

  expandTillCurrentFolder(props) {
    function expandFolder(folderIndex) {
      const folder = props.rootTillCurrentFolder && props.rootTillCurrentFolder[folderIndex]
      if (!folder) return
      return folder
        .expand(false, {onlyShowSubtrees: true})
        .then(() => expandFolder(folderIndex + 1))
    }

    return expandFolder(0)
  },
}
