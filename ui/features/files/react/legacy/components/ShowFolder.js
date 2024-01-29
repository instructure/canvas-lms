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
import page from 'page'
import {debounce} from 'lodash'
import {useScope as useI18nScope} from '@canvas/i18n'
import filesEnv from '@canvas/files/react/modules/filesEnv'
import getAllPages from '../util/getAllPages'
import updateAPIQuerySortParams from '../util/updateAPIQuerySortParams'
import Folder from '@canvas/files/backbone/models/Folder'

const I18n = useI18nScope('react_files')

const LEADING_SLASH_TILL_BUT_NOT_INCLUDING_NEXT_SLASH = /^\/[^\/]*/

export default {
  displayName: 'ShowFolder',

  debouncedForceUpdate: debounce(function () {
    // eslint-disable-next-line react/no-is-mounted
    if (this.isMounted()) this.forceUpdate()
  }, 0),

  previousIdentifier: '',

  registerListeners(props) {
    if (!props.currentFolder) return
    props.currentFolder.folders.on('all', this.debouncedForceUpdate, this)
    props.currentFolder.files.on('all', this.debouncedForceUpdate, this)
  },

  unregisterListeners() {
    // Ensure that we clean up any dangling references when the component is destroyed.
    this.props.currentFolder && this.props.currentFolder.off(null, null, this)
  },

  getCurrentFolder(options = {}) {
    let contextId, contextType
    let path = `/${options.splat || ''}`

    if (filesEnv.showingAllContexts) {
      const pluralAssetString = path.split('/')[1]
      const context = filesEnv.contextsDictionary[pluralAssetString] || filesEnv.contexts[0]
      ;({contextType, contextId} = context)
      path = path.replace(LEADING_SLASH_TILL_BUT_NOT_INCLUDING_NEXT_SLASH, '')
    } else {
      ;({contextType, contextId} = filesEnv)
    }

    return Folder.resolvePath(contextType, contextId, path).then(
      rootTillCurrentFolder => {
        const currentFolder = rootTillCurrentFolder[rootTillCurrentFolder.length - 1]
        this.props.onResolvePath({
          currentFolder,
          rootTillCurrentFolder,
          showingSearchResults: false,
        })

        return [currentFolder.folders, currentFolder.files].forEach(collection => {
          updateAPIQuerySortParams(collection, this.props.query)
          // TODO: use scroll position to only fetch the pages we need
          return getAllPages(collection, this.debouncedForceUpdate)
        })
      },
      jqXHR => {
        let parsedResponse
        try {
          parsedResponse = JSON.parse(jqXHR.responseText)
        } catch (error) {
          // no-op
        }
        if (parsedResponse) {
          this.setState({errorMessages: parsedResponse.errors})
          if (this.props.query.preview != null) {
            return this.redirectToCourseFiles()
          }
        }
      }
    )
  },

  UNSAFE_componentWillMount() {
    this.registerListeners(this.props)
    this.getCurrentFolder(this.props)
  },

  componentWillUnmount() {
    this.unregisterListeners()
  },

  componentDidUpdate() {
    if (
      this.props.currentFolder == null ||
      (this.props.currentFolder && this.props.currentFolder.get('locked_for_user'))
    ) {
      return this.redirectToCourseFiles()
    }
  },

  UNSAFE_componentWillReceiveProps(newProps) {
    this.unregisterListeners()
    if (!newProps.currentFolder) return
    if (this.props.pathname !== newProps.pathname) {
      this.getCurrentFolder(newProps)
    }
    this.registerListeners(newProps)
    ;[newProps.currentFolder.folders, newProps.currentFolder.files].forEach(collection => {
      updateAPIQuerySortParams(collection, this.props.query)
    })
  },

  redirectToCourseFiles() {
    const isntPreviousFolder =
      this.props.currentFolder != null &&
      (this.previousIdentifier != null) !== this.props.currentFolder.get('id').toString()
    const isPreviewForFile =
      window.location.pathname !== filesEnv.baseUrl &&
      this.props.query.preview != null &&
      this.previousIdentifier !== this.props.query.preview

    if (isntPreviousFolder || isPreviewForFile) {
      this.previousIdentifier =
        (this.props.currentFolder && this.props.currentFolder.get('id').toString()) ||
        this.props.query.preview.toString()

      if (!isPreviewForFile) {
        const message = I18n.t('This folder is currently locked and unavailable to view.')
        $.flashError(message)
        $.screenReaderFlashMessage(message)
      }

      return setTimeout(() => page(`${filesEnv.baseUrl}?${$.param(this.props.query)}`), 0)
    }
  },
}
