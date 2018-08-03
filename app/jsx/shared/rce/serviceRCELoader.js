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

import $ from 'jquery'
import _ from 'underscore'
import {refreshFn as refreshToken} from '../jwt'
import editorOptions from '../rce/editorOptions'
import loadEventListeners from '../rce/loadEventListeners'
import polyfill from '../rce/polyfill'
import splitAssetString from 'compiled/str/splitAssetString'

  const RCELoader = {
    preload() {
      this.loadRCE(function(){})
    },

    loadOnTarget(target, tinyMCEInitOptions, callback) {
      const textarea = this.getTargetTextarea(target)
      const renderingTarget = this.getRenderingTarget(textarea, tinyMCEInitOptions.getRenderingTarget)
      const propsForRCE = this.createRCEProps(textarea, tinyMCEInitOptions)

      this.loadRCE(function(RCE) {
        RCE.renderIntoDiv(renderingTarget, propsForRCE, function(remoteEditor) {
          remoteEditor.mceInstance().on('init', () => callback(textarea, polyfill.wrapEditor(remoteEditor)))
        })
      })
    },

    loadSidebarOnTarget(target, callback) {
      if (ENV.RICH_CONTENT_SKIP_SIDEBAR) {
        return
      }
      let context = splitAssetString(ENV.context_asset_string)
      let props = {
        jwt: ENV.JWT,
        refreshToken: refreshToken(ENV.JWT),
        host: ENV.RICH_CONTENT_APP_HOST,
        canUploadFiles: ENV.RICH_CONTENT_CAN_UPLOAD_FILES,
        filesTabDisabled: ENV.RICH_CONTENT_FILES_TAB_DISABLED,
        contextType: context[0],
        contextId: context[1],
        themeUrl: ENV.active_brand_config_json_url
      }
      this.loadRCE(function (RCE) {
        RCE.renderSidebarIntoDiv(target, props, function(remoteSidebar) {
          callback(polyfill.wrapSidebar(remoteSidebar))
        })
      })
    },

    /**
    * properties for managing several requests to load
    * the module from various pieces of canvas code.
    *
    * @private
    */
    loadingFlag: false,
    loadingCallbacks: [],
    RCE: null,
    loadEventListeners,

    /**
    * handle accepting new load requests depending on the current state
    * of the load/cache cycle
    *
    * @private
    */
    loadRCE(cb) {
      require.ensure([], (require) => {
        const first = !this.RCE
        this.RCE = require('canvas-rce/lib/async')
        require('./initA11yChecker')
        if (first) {
          this.loadEventListeners()
          this.loadingFlag = false
        }
        this.loadingCallbacks.forEach((loadingCallback) => {
          loadingCallback(this.RCE)
        })
        this.loadingCallbacks = []
        cb(this.RCE)
      }, 'CanvasRCEAsyncChunk')
    },

    /**
    * sometimes we get passed a container that has the
    * textarea nested within it, we want to normalize to
    * just using whatever textarea is going to be bound to
    * the editor
    *
    * @private
    * @return {Element} the textarea
    */
    getTargetTextarea(initialTarget) {
      return $(initialTarget).get(0).type == "textarea" ?
        $(initialTarget).get(0) :
        $(initialTarget).find("textarea").get(0)
    },

    /**
    * the immediate parent of the textarea is the container
    * we want to render the remote react component inside, so it's
    * a sibiling with the actual form element being populated.
    *
    * @private
    * @return {Element} container element for rendering remote editor
    */
    getRenderingTarget(textarea, getTargetFn = undefined) {
      let renderingTarget

      if (typeof getTargetFn === 'undefined') {
        renderingTarget = $(textarea).parent().get(0)
      } else {
        renderingTarget = getTargetFn(textarea)
      }
      $(renderingTarget).addClass('ic-RichContentEditor')

      return renderingTarget
    },

    /**
    * anything that canvas needs to later find this
    * editor/textarea should be mirrored here so we
    * dont have to change too much canvas code
    *
    * @private
    * @return {Hash}
    */
    _attrsToMirror(textarea) {
      let validAttrs = ["name"]
      let attrs = _.reduce(textarea.attributes, (memo, attr) => {
        memo[attr.name] = attr.value
        return memo
      }, {})

      return _.pick(attrs, validAttrs)
    },

    /**
     * merges options provided by consuming code with some
     * intelligent defaults so that simple use cases can not
     * worry about providing repetitive options hashes.
     *
     * @private
     * @return {Hash} ready-to-use options hash to use as react props
     */
    createRCEProps(textarea, tinyMCEInitOptions) {
      let width = textarea.offsetWidth
      let height = textarea.offsetHeight

      if (height){
        tinyMCEInitOptions.tinyOptions = _.extend({},
          {height: height},
          (tinyMCEInitOptions.tinyOptions || {})
        )
      }

      return {
        editorOptions: editorOptions.bind(null, width, textarea.id, tinyMCEInitOptions, null),
        defaultContent: textarea.value || tinyMCEInitOptions.defaultContent,
        textareaId: textarea.id,
        textareaClassName: textarea.className,
        language: ENV.LOCALE,
        mirroredAttrs: this._attrsToMirror(textarea),
        onFocus: tinyMCEInitOptions.onFocus
      }
    },

    /**
     * helps with url construction which is different when using a CDN
     * than when loading directly from an RCE server
     *
     * @private
     * @return {String} ready-to-use URL for loading RCE remotely
     */
    buildModuleUrl() {
      let host, path
      if (window.ENV.RICH_CONTENT_CDN_HOST) {
        host = window.ENV.RICH_CONTENT_CDN_HOST
        path = '/latest'
      } else {
        host = window.ENV.RICH_CONTENT_APP_HOST
        path = '/get_module'
      }
      // trim trailing slash if there is one, as we're going to add one below
      host = host.replace(/\/$/, "")
      return '//' + host + path
    }
  }

export default RCELoader
