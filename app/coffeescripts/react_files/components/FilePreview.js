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
import _ from 'underscore'
import PureRenderMixin from 'react-addons-pure-render-mixin'
import PropTypes from 'prop-types'
import customPropTypes from '../modules/customPropTypes'
import Backbone from 'Backbone'
import I18n from 'i18n!file_preview'
import File from '../../models/File'
import FilesystemObject from '../../models/FilesystemObject'
import filesEnv from '../modules/filesEnv'
import codeToRemoveLater from 'jsx/files/codeToRemoveLater'
import '../../jquery.rails_flash_notifications'

export default {
  displayName: 'FilePreview',

  mixins: [PureRenderMixin],

  propTypes: {
    currentFolder: customPropTypes.folder,
    query: PropTypes.object,
    collection: PropTypes.object,
    params: PropTypes.object,
    isOpen: PropTypes.bool,
    closePreview: PropTypes.func
  },

  getInitialState() {
    return {
      showInfoPanel: false,
      displayedItem: null
    }
  },

  componentWillMount() {
    if (this.props.isOpen) {
      let items
      return (items = this.getItemsToView(this.props, items =>
        this.setState(this.stateProperties(items, this.props))
      ))
    }
  },

  componentDidMount() {
    $('.ReactModal__Overlay').on('keydown', this.handleKeyboardNavigation)
    return codeToRemoveLater.hideFileTreeFromPreviewInJaws()
  },

  componentWillUnmount() {
    $('.ReactModal__Overlay').off('keydown', this.handleKeyboardNavigation)
    return codeToRemoveLater.revertJawsChangesBackToNormal()
  },

  componentWillReceiveProps(newProps) {
    if (newProps.isOpen) {
      let items
      return (items = this.getItemsToView(newProps, items =>
        this.setState(this.stateProperties(items, newProps))
      ))
    }
  },

  getItemsToView(props, cb) {
    // Sets up our collection that we will be using.
    let initialItem = null
    const onlyIdsToPreview = props.query.only_preview && props.query.only_preview.split(',')
    const files = props.query.search_term
      ? props.collection.models
      : props.currentFolder.files.models

    const otherItems = files.filter(function(file) {
      if (!onlyIdsToPreview) return true
      return onlyIdsToPreview.includes(file.id)
    })

    const visibleFile = props.query.preview && _.findWhere(files, {id: props.query.preview})

    if (!visibleFile) {
      const responseDataRequested = ['enhanced_preview_url']
      if (props.usageRightsRequiredForContext) {
        responseDataRequested.push('usage_rights')
      }
      return new File({id: props.query.preview}, {preflightUrl: 'no/url/needed'})
        .fetch({data: $.param({include: responseDataRequested})})
        .success(function(file) {
          initialItem = new FilesystemObject(file)
          if (typeof cb === 'function') return cb({initialItem, otherItems})
        })
    } else {
      initialItem = visibleFile || (files.length ? files[0] : undefined)

      if (typeof cb === 'function') return cb({initialItem, otherItems})
    }
  },

  stateProperties(items, props) {
    return {
      initialItem: items.initialItem,
      displayedItem: items.initialItem,
      otherItems: items.otherItems,
      currentFolder: props.currentFolder,
      params: props.params,
      otherItemsString: props.query.only_preview ? props.query.only_preview : undefined,
      otherItemsIsBackBoneCollection: items.otherItems instanceof Backbone.Collection
    }
  },

  setUpOtherItemsQuery(otherItems) {
    return otherItems.map(item => item.id).join(',')
  },

  getNavigationParams(opts = {id: null, except: []}) {
    const obj = {
      preview: opts.id ? opts.id : undefined,
      search_term: this.props.query.search_term ? this.props.query.search_term : undefined,
      only_preview: this.state.otherItemsString ? this.state.otherItemsString : undefined,
      sort: this.props.query.sort ? this.props.query.sort : undefined,
      order: this.props.query.order ? this.props.query.order : undefined
    }

    _.each(obj, function(v, k) {
      if (
        !v ||
        (opts.except && opts.except.length && (opts.except === k || opts.except.includes(k)))
      ) {
        delete obj[k]
      }
    })

    return obj
  },

  toggle(key) {
    const newState = {}
    newState[key] = !this.state[key]
    return () => {
      this.setState(newState, function() {
        if (key === 'showInfoPanel' && this.state.showInfoPanel) {
          $.screenReaderFlashMessage(I18n.t('Info panel displayed'))
        } else {
          $.screenReaderFlashMessage(I18n.t('Info panel hidden'))
        }
      })
    }
  }
}
