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
import editorOptions from './editorOptions'
import loadEventListeners from './loadEventListeners'
import polyfill from './polyfill'
import getRCSProps from './getRCSProps'
import closedCaptionLanguages from '@canvas/util/closedCaptionLanguages'
import shouldUseFeature, {Feature} from './shouldUseFeature'

const RCELoader = {
  loadingPromise: null,

  preload(cb) {
    // since we are just preloading, let other stuff waiting to run go first so we don't slow pageload
    ;(window.requestIdleCallback || window.setTimeout)(() => this.loadRCE(cb))
  },

  loadOnTarget(target, tinyMCEInitOptions, callback) {
    const textarea = this.getTargetTextarea(target)
    const renderingTarget = this.getRenderingTarget(textarea, tinyMCEInitOptions.getRenderingTarget)
    const propsForRCE = this.createRCEProps(textarea, tinyMCEInitOptions)

    this.loadRCE(RCE => {
      RCE.renderIntoDiv(renderingTarget, propsForRCE, remoteEditor => {
        remoteEditor.tinymceOn('init', () => callback(textarea, polyfill.wrapEditor(remoteEditor)))
      })
    })
  },

  /**
   * properties for managing several requests to load
   * the module from various pieces of canvas code.
   *
   * @private
   */
  loadingCallbacks: [],
  RCE: null,

  /**
   * handle accepting new load requests depending on the current state
   * of the load/cache cycle.
   *
   * @return {Promise}
   * @private
   */
  loadRCE(cb = () => {}) {
    return import(/* webpackChunkName: "canvas-rce-async-chunk" */ './canvas-rce')
      .then(RCE => {
        this.RCE = RCE
        loadEventListeners()
        return RCE
      })
      .then(() => {
        this.loadingCallbacks.forEach(loadingCallback => loadingCallback(this.RCE))
        this.loadingCallbacks = []
        // eslint-disable-next-line promise/no-callback-in-promise
        cb(this.RCE)
      })
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
    return $(initialTarget).get(0).type === 'textarea'
      ? $(initialTarget).get(0)
      : $(initialTarget).find('textarea').get(0)
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
    const validAttrs = ['name']
    const attrs = _.reduce(
      textarea.attributes,
      (memo, attr) => {
        memo[attr.name] = attr.value
        return memo
      },
      {}
    )

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
    const width = textarea.offsetWidth
    const height = textarea.offsetHeight || 400

    if (height) {
      tinyMCEInitOptions.tinyOptions = {
        height,
        ...(tinyMCEInitOptions.tinyOptions || {})
      }
    }

    const myLanguage = ENV.LOCALE
    const languages = Object.keys(closedCaptionLanguages)
      .map(locale => {
        return {id: locale, label: closedCaptionLanguages[locale]}
      })
      .sort((a, b) => {
        if (a.id === myLanguage) {
          return -1
        } else if (b.id === myLanguage) {
          return 1
        } else {
          return a.label.localeCompare(b.label, myLanguage)
        }
      })

    // TODO: let client pass autosave_enabled in as a prop from the outside
    //       Assignmens2 student view is going to be doing their own autosave
    const autosave = {
      enabled: true,
      maxAge: Number.isNaN(ENV.rce_auto_save_max_age_ms) ? 3600000 : ENV.rce_auto_save_max_age_ms
    }

    return {
      defaultContent: textarea.value || tinyMCEInitOptions.defaultContent,
      editorOptions: editorOptions.bind(null, width, textarea.id, tinyMCEInitOptions, null),
      language: ENV.LOCALE,
      mirroredAttrs: this._attrsToMirror(textarea),
      onFocus: tinyMCEInitOptions.onFocus,
      onBlur: tinyMCEInitOptions.onBlur,
      textareaClassName: textarea.className,
      textareaId: textarea.id,
      trayProps: getRCSProps(),
      languages,
      liveRegion: () => document.getElementById('flash_screenreader_holder'),
      ltiTools: window.INST?.editorButtons,
      autosave: tinyMCEInitOptions.autosave || autosave,
      instRecordDisabled: ENV.RICH_CONTENT_INST_RECORD_TAB_DISABLED,
      maxInitRenderedRCEs: tinyMCEInitOptions.maxInitRenderedRCEs,
      highContrastCSS: window.ENV?.url_for_high_contrast_tinymce_editor_css,
      use_rce_buttons_and_icons: shouldUseFeature(Feature.ButtonsAndIcons, window.ENV)
    }
  }
}

export default RCELoader
