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
import page from 'page'
import $ from 'jquery'
import {each, find} from 'lodash'
import classnames from 'classnames'
import {Mask, Overlay} from '@instructure/ui-overlays'
import FilePreviewInfoPanel from './FilePreviewInfoPanel'
import CollectionHandler from '../../util/collectionHandler'
import preventDefault from '@canvas/util/preventDefault'

import PropTypes from 'prop-types'
import customPropTypes from '../modules/customPropTypes'
import {useScope as useI18nScope} from '@canvas/i18n'
import File from '../../backbone/models/File'
import FilesystemObject from '../../backbone/models/FilesystemObject'
import codeToRemoveLater from '../../jquery/codeToRemoveLater'
import '@canvas/rails-flash-notifications'

const I18n = useI18nScope('file_preview')

export default class FilePreview extends React.PureComponent {
  static propTypes = {
    currentFolder: PropTypes.oneOfType([
      customPropTypes.folder,
      PropTypes.shape({
        files: PropTypes.shape({
          models: PropTypes.arrayOf(PropTypes.instanceOf(File)),
        }),
      }),
    ]),
    query: PropTypes.object,
    collection: PropTypes.object,
    params: PropTypes.object,
    isOpen: PropTypes.bool,
    closePreview: PropTypes.func,
    splat: PropTypes.string,
    usageRightsRequiredForContext: PropTypes.bool,
  }

  state = {
    showInfoPanel: false,
    displayedItem: null,
  }

  UNSAFE_componentWillMount() {
    if (this.props.isOpen) {
      this.getItemsToView(this.props, items => this.setState(this.stateProperties(items)))
    }
  }

  componentDidMount() {
    return codeToRemoveLater.hideFileTreeFromPreviewInJaws()
  }

  UNSAFE_componentWillReceiveProps(newProps) {
    if (newProps.isOpen) {
      this.getItemsToView(newProps, items => this.setState(this.stateProperties(items)))
    }
  }

  componentWillUnmount() {
    $(this.previewOverlay).on('keydown', this.handleKeyboardNavigation)
    return codeToRemoveLater.revertJawsChangesBackToNormal()
  }

  getRouteIdentifier = () => {
    if (this.props.query && this.props.query.search_term) {
      return '/search'
    } else if (this.props.splat) {
      return `/folder/${this.props.splat}`
    } else {
      return ''
    }
  }

  getNavigationParams = (opts = {id: null, except: []}) => {
    const obj = {
      preview: opts && opts.id,
      search_term: this.props.query.search_term || undefined,
      only_preview: this.props.query.only_preview || undefined,
      sort: this.props.query.sort || undefined,
      order: this.props.query.order || undefined,
    }

    each(obj, (v, k) => {
      if (
        !v ||
        (opts.except && opts.except.length && (opts.except === k || opts.except.includes(k)))
      ) {
        delete obj[k]
      }
    })

    return obj
  }

  getItemsToView = (props, cb) => {
    if (typeof cb !== 'function')
      throw new Error(
        'getItemsToView(props: obj, callback: fn) requires `callback` to be a function'
      )
    // Sets up our collection that we will be using.
    let initialItem = null
    const onlyIdsToPreview = props.query.only_preview && props.query.only_preview.split(',')
    const files = props.query.search_term
      ? props.collection.models
      : props.currentFolder.files.models

    const otherItems = files.filter(file => {
      if (!onlyIdsToPreview) return true
      return onlyIdsToPreview.includes(file.id)
    })

    const visibleFile = props.query.preview && find(files, {id: props.query.preview})

    if (!visibleFile) {
      const responseDataRequested = ['enhanced_preview_url']
      if (props.usageRightsRequiredForContext) {
        responseDataRequested.push('usage_rights')
      }
      new File({id: props.query.preview}, {preflightUrl: 'no/url/needed'})
        .fetch({data: $.param({include: responseDataRequested})})
        .success(file => {
          initialItem = new FilesystemObject(file)
          return cb({initialItem, otherItems})
        })
    } else {
      initialItem = visibleFile || (files.length ? files[0] : undefined)

      cb({initialItem, otherItems})
    }
  }

  setUpOtherItemsQuery = otherItems => otherItems.map(item => item.id).join(',')

  toggle = key => {
    const newState = {}
    newState[key] = !this.state[key]
    return () => {
      this.setState(newState, function () {
        if (key === 'showInfoPanel' && this.state.showInfoPanel) {
          $.screenReaderFlashMessage(I18n.t('Info panel displayed'))
        } else {
          $.screenReaderFlashMessage(I18n.t('Info panel hidden'))
        }
      })
    }
  }

  handleKeyboardNavigation = event => {
    if (!(event.keyCode === $.ui.keyCode.LEFT || event.keyCode === $.ui.keyCode.RIGHT)) {
      return null
    }
    let nextItem = null
    if (event.keyCode === $.ui.keyCode.LEFT) {
      nextItem = CollectionHandler.getPreviousInRelationTo(
        this.state.otherItems,
        this.state.displayedItem
      )
    }
    if (event.keyCode === $.ui.keyCode.RIGHT) {
      nextItem = CollectionHandler.getNextInRelationTo(
        this.state.otherItems,
        this.state.displayedItem
      )
    }

    page(`${this.getRouteIdentifier()}?${$.param(this.getNavigationParams({id: nextItem.id}))}`)
  }

  closeModal = () => {
    this.props.closePreview(
      `${this.getRouteIdentifier()}?${$.param(this.getNavigationParams({except: 'only_preview'}))}`
    )
  }

  stateProperties = items => ({
    initialItem: items.initialItem,
    displayedItem: items.initialItem,
    otherItems: items.otherItems,
  })

  renderArrowLink = direction => {
    const nextItem =
      direction === 'left'
        ? CollectionHandler.getPreviousInRelationTo(this.state.otherItems, this.state.displayedItem)
        : CollectionHandler.getNextInRelationTo(this.state.otherItems, this.state.displayedItem)
    if (!nextItem) {
      return null
    }

    const linkText = direction === 'left' ? I18n.t('View previous file') : I18n.t('View next file')
    const baseUrl = page.base()
    return (
      <div className="col-xs-1 ef-file-arrow_container">
        <a
          href={`${baseUrl}${this.getRouteIdentifier()}?${$.param(
            this.getNavigationParams({id: nextItem.id})
          )}`}
          className="ef-file-preview-container-arrow-link"
          onClick={e => page.clickHandler(e.nativeEvent)}
        >
          <div className="ef-file-preview-arrow-link">
            <span className="screenreader-only">{linkText}</span>
            <i aria-hidden="true" className={`icon-arrow-open-${direction}`} />
          </div>
        </a>
      </div>
    )
  }

  renderPreview = () => {
    if (this.state.displayedItem && this.state.displayedItem.get('preview_url')) {
      const html = this.state.displayedItem.get('content-type') === 'text/html'
      const iFrameClasses = classnames({
        'ef-file-preview-frame': true,
        'ef-file-preview-frame-html': html,
        'attachment-html-iframe': html,
      })

      return (
        <iframe
          allowFullScreen={true}
          title={I18n.t('File Preview')}
          src={this.state.displayedItem.get('preview_url')}
          className={iFrameClasses}
        />
      )
    } else {
      return (
        <div className="ef-file-not-found ef-file-preview-frame">
          <i className="media-object ef-not-found-icon FilesystemObjectThumbnail mimeClass-file" />
          {I18n.t('File not found')}
        </div>
      )
    }
  }

  render() {
    const showInfoPanelClasses = classnames({
      'ef-file-preview-header-info': true,
      'ef-file-preview-button': true,
      'ef-file-preview-button--active': this.state.showInfoPanel,
    })

    return (
      <Overlay
        ref={e => (this.previewOverlay = e)}
        open={this.props.isOpen}
        onDismiss={this.closeModal}
        onKeyDown={this.handleKeyboardNavigation}
        label={I18n.t('File Preview Overlay')}
        defaultFocusElement={() => this.closeButton}
        shouldContainFocus={true}
        shouldReturnFocus={true}
        unmountOnExit={true}
      >
        <Mask themeOverride={{background: 'rgba(0, 0, 0, 0.75)'}}>
          <div className="ef-file-preview-overlay">
            <div className="ef-file-preview-header">
              <h1 className="ef-file-preview-header-filename">
                {this.state.initialItem ? this.state.initialItem.displayName() : ''}
              </h1>
              <div className="ef-file-preview-header-buttons">
                {this.state.displayedItem && !this.state.displayedItem.get('locked_for_user') && (
                  <a
                    href={this.state.displayedItem.get('url')}
                    download={true}
                    className="ef-file-preview-header-download ef-file-preview-button"
                  >
                    <i className="icon-download" />
                    <span className="hidden-phone">{` ${I18n.t('Download')}`}</span>
                  </a>
                )}
                <button
                  type="button"
                  className={showInfoPanelClasses}
                  ref={e => (this.infoButton = e)}
                  onClick={this.toggle('showInfoPanel')}
                  aria-expanded={this.state.showInfoPanel}
                >
                  {/* Wrap content in a div because firefox doesn't support display: flex on buttons */}
                  <div>
                    <i className="icon-info" />
                    <span className="hidden-phone">{` ${I18n.t('Info')}`}</span>
                  </div>
                </button>
                <button
                  type="button"
                  onClick={preventDefault(this.closeModal)}
                  ref={e => (this.closeButton = e)}
                  className="ef-file-preview-header-close ef-file-preview-button"
                >
                  <i className="icon-end" />
                  <span className="hidden-phone">{` ${I18n.t('Close')}`}</span>
                </button>
              </div>
            </div>
            <div className="ef-file-preview-stretch">
              {this.state.otherItems &&
                !!this.state.otherItems.length &&
                this.renderArrowLink('left')}
              {this.renderPreview()}
              {this.state.otherItems &&
                !!this.state.otherItems.length &&
                this.renderArrowLink('right')}
              {this.state.showInfoPanel && (
                <FilePreviewInfoPanel
                  displayedItem={this.state.displayedItem}
                  getStatusMessage={this.getStatusMessage}
                  usageRightsRequiredForContext={this.props.usageRightsRequiredForContext}
                />
              )}
            </div>
          </div>
        </Mask>
      </Overlay>
    )
  }
}
