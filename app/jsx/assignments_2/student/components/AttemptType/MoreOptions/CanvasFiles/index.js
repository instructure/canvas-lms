/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import {arrayOf, shape, string} from 'prop-types'
import axios from 'axios'
import errorShipUrl from '../../../../SVG/ErrorShip.svg'
import GenericErrorPage from '../../../../../../shared/components/GenericErrorPage/index'
import I18n from 'i18n!assignments_2'
import parseLinkHeader from '../../../../../../shared/parseLinkHeader'
import React from 'react'

import TreeBrowser from '@instructure/ui-tree-browser/lib/components/TreeBrowser'

class CanvasFiles extends React.Component {
  state = {
    collections: {0: {collections: []}},
    error: null
  }

  _isMounted = false

  componentDidMount() {
    this._isMounted = true
    this.getUserRootFolders()
  }

  componentWillUnmount() {
    this._isMounted = false
  }

  getUserRootFolders = () => {
    const opts = {Accept: 'application/json+canvas-string-ids'}
    // update user folders
    this.updateFolders('/api/v1/users/self/folders/root', opts)

    // update course folders
    this.updateFolders(`/api/v1/courses/${this.props.courseID}/folders/root`, opts)

    // update group folders
    this.props.userGroups.forEach(group => {
      this.updateFolders(`/api/v1/groups/${group._id}/folders/root`, {...opts, name: group.name})
    })
  }

  folderFileApiUrl = folderID => {
    return `/api/v1/folders/${folderID}/folders`
  }

  formatFolderData = (folder, opts) => {
    return {
      id: folder.id,
      collections: [],
      items: [],
      name: opts.name ? opts.name : folder.name,
      context: `/${folder.context_type.toLowerCase()}s/${folder.context_id}`,
      locked: folder.locked_for_user,
      descriptor: folder.locked_for_user ? I18n.t('Locked') : null
    }
  }

  updateFolders = async (url, opts = {}) => {
    try {
      const resp = await axios.get(url, opts)
      const folders = Array.isArray(resp.data) ? resp.data : [resp.data]
      this.updateCollectionsList(folders, opts)

      const nextUrl = parseLinkHeader(resp.headers.link).next
      if (nextUrl) {
        this.updateFolders(nextUrl)
      }

      folders.forEach(folder => {
        if (folder.folders_count > 0) {
          this.updateFolders(this.folderFileApiUrl(folder.id, 'folders'))
        }
      })
    } catch (err) {
      if (this._isMounted) {
        this.setState({error: err})
      }
    }
  }

  updateCollectionsList = (folders, opts) => {
    if (this._isMounted) {
      this.setState(prevState => {
        const newCollections = JSON.parse(JSON.stringify(prevState.collections))
        folders.forEach(folder => {
          const collection = this.formatFolderData(folder, opts)
          const parent_id = folder.parent_folder_id || 0

          // get or create parent collection object
          const parent = newCollections.hasOwnProperty(parent_id)
            ? newCollections[parent_id]
            : {collections: []}
          if (!parent.collections.includes(collection.id)) {
            parent.collections.push(collection.id)
            newCollections[parent_id] = {...newCollections[parent_id], ...parent}
          }

          if (newCollections[collection.id]) {
            collection.collections = newCollections[collection.id].collections
          }
          newCollections[collection.id] = collection
        })
        return {collections: newCollections}
      })
    }
  }

  render() {
    if (this.state.error) {
      return (
        <GenericErrorPage
          imageUrl={errorShipUrl}
          errorSubject={this.state.error.message}
          errorCategory={I18n.t('Assignments 2 Student Error Page')}
        />
      )
    }
    return (
      <TreeBrowser
        rootId={0}
        showRootCollection={false}
        collections={this.state.collections}
        items={{}}
        size="small"
        variant="indent"
      />
    )
  }
}

CanvasFiles.propTypes = {
  courseID: string.isRequired,
  userGroups: arrayOf(
    shape({
      _id: string,
      name: string
    })
  )
}

export default CanvasFiles
