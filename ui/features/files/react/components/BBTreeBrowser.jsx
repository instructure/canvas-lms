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

import React from 'react'
import PropTypes from 'prop-types'
import ReactDOM from 'react-dom'
import customPropTypes from '@canvas/files/react/modules/customPropTypes'
import {useScope as useI18nScope} from '@canvas/i18n'
import BBTreeBrowserView from '../legacy/modules/BBTreeBrowserView'
import RootFoldersFinder from '../../RootFoldersFinder'

const I18n = useI18nScope('react_files')

class BBTreeBrowser extends React.Component {
  static displayName = 'BBTreeBrowser'

  static propTypes = {
    rootFoldersToShow: PropTypes.arrayOf(customPropTypes.folder).isRequired,
    onSelectFolder: PropTypes.func.isRequired,
  }

  componentDidMount() {
    const rootFoldersFinder = new RootFoldersFinder({
      rootFoldersToShow: this.props.rootFoldersToShow,
    })

    this.treeBrowserViewId = BBTreeBrowserView.create(
      {
        onlyShowSubtrees: true,
        rootModelsFinder: rootFoldersFinder,
        rootFoldersToShow: this.props.rootFoldersToShow,
        onClick: this.props.onSelectFolder,
        focusStyleClass: 'MoveDialog__folderItem--focused',
        selectedStyleClass: 'MoveDialog__folderItem--selected',
      },
      {
        element: ReactDOM.findDOMNode(this.refs.FolderTreeHolder),
      }
    ).index

    window.setTimeout(() => {
      BBTreeBrowserView.getView(this.treeBrowserViewId)
        .render()
        .$el.appendTo(ReactDOM.findDOMNode(this.refs.FolderTreeHolder))
        .find(':tabbable:first')
        .focus()
    }, 0)
  }

  componentWillUnmount() {
    BBTreeBrowserView.remove(this.treeBrowserViewId)
  }

  render() {
    return (
      <aside role="region" aria-label={I18n.t('folder_browsing_tree', 'Folder Browsing Tree')}>
        <div ref="FolderTreeHolder" />
      </aside>
    )
  }
}

export default BBTreeBrowser
