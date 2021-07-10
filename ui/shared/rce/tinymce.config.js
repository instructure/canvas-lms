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

import {getDirection} from '@canvas/i18n/rtlHelper'
import defaultTinymceConfig from '@instructure/canvas-rce/es/defaultTinymceConfig'

const new_rce = window.ENV.use_rce_enhancements
export default class EditorConfig {
  /**
   * Create an editor config instance, with some internal state passed in
   *   so the object knows how to generate a dynamic hash of default
   *   configuration parameters.  May get overridden by merging
   *   with another hash of overwriting config parameters.
   *
   *  @param {tinymce} tinymce the tinymce global which we use to pull
   *    some config info off of like the BaseURL for refrencing the skin css
   *  @param {INST} inst a config hash defined in public/javascripts/INST.js,
   *    provides feature information like whether notorious is enabled for
   *    their account.  Generally you can just pass it in after requiring it.
   *  @param {int} width The width of the viewport the editor is in, this is
   *    useful for deciding how many buttons to show per toolbar line
   *  @param {string} domId the "id" attribute of the element that's going
   *    to be transformed with a tinymce editor
   *
   *  @exports
   *  @constructor
   *  @return {EditorConfig}
   */
  constructor(tinymce, inst, width, domId) {
    this.baseURL = tinymce.baseURL
    this.maxButtons = inst.maxVisibleEditorButtons
    this.extraButtons = inst.editorButtons
    this.instConfig = inst
    this.viewportWidth = width
    this.idAttribute = domId
  }

  /**
   * export an appropriate config hash for this config instance.
   * This returns a simple javascript object with our default
   * configuration parameters enabled.  You can override
   * any configuration parameters you want by combining this hash
   * with an override hash at runtime using "$.extend" or similar:
   *
   *   var overrides = { resize: false };
   *   var tinyOptions = $.extend(editorConfig.defaultConfig(), overrides);
   *   tinymce.init(tinyOptions);
   *
   * @return {Hash}
   */
  defaultConfig() {
    const new_rce_plugins = ['instructure_equation']
    if (this.extraButtons?.length) {
      new_rce_plugins.push('instructure_external_tools')
    }

    return {
      ...defaultTinymceConfig,

      body_class:
        window.ENV.FEATURES?.canvas_k6_theme ||
        window.ENV.K5_SUBJECT_COURSE ||
        window.ENV.K5_HOMEROOM_COURSE
          ? 'elementary-theme'
          : 'default-theme',
      selector: `#${this.idAttribute}`,
      [!new_rce && 'toolbar']: this.toolbar(), // handled in RCEWrapper
      [!new_rce && 'theme']: 'modern',
      [!new_rce && 'skin']: false,
      directionality: getDirection(),
      plugins: new_rce
        ? new_rce_plugins
        : 'autolink,media,paste,table,lists,textcolor,link,directionality,a11y_checker,wordcount,' +
          'instructure_image,instructure_links,instructure_equation,instructure_external_tools,instructure_record',

      content_css: window.ENV.url_to_what_gets_loaded_inside_the_tinymce_editor_css,

      menubar: new_rce ? undefined : true,

      init_instance_callback: ed => {
        $(`#tinymce-parent-of-${ed.id}`) // eslint-disable-line no-undef
          .css('visibility', 'visible')
      },
      // if kalturaSettings is missing, we have no kaltura to upload to
      // if present, user may have chosen to hide the button anyway.
      show_media_upload: !!INST.kalturaSettings && !INST.kalturaSettings.hide_rte_button
    }
  }

  /**
   * builds the configuration information that decides whether to clump
   * up external buttons or not based on the number of extras we
   * want to add.
   *
   * @private
   * @return {String} comma delimited set of external buttons
   */
  external_buttons() {
    let externals = ''
    for (let idx = 0; this.extraButtons && idx < this.extraButtons.length; idx++) {
      if (this.extraButtons.length <= this.maxButtons || idx < this.maxButtons - 1) {
        externals = `${externals} instructure_external_button_${this.extraButtons[idx].id}`
      } else if (!externals.match(/instructure_external_button_clump/)) {
        externals += ' instructure_external_button_clump'
      }
    }
    return externals
  }

  /**
   * uses externally provided settings to decide which instructure
   * plugin buttons to enable, and returns that string of button names.
   *
   * @private
   * @return {String} comma delimited set of non-core buttons
   */
  buildInstructureButtons() {
    let instructure_buttons = ` instructure_image instructure_equation${
      new_rce ? ' lti_tool_dropdown' : ''
    }`
    instructure_buttons += this.external_buttons()
    if (
      this.instConfig &&
      this.instConfig.allowMediaComments &&
      this.instConfig.kalturaSettings &&
      !this.instConfig.kalturaSettings.hide_rte_button
    ) {
      instructure_buttons += ' instructure_record'
    }
    const equella_button =
      this.instConfig && this.instConfig.equellaEnabled ? ' instructure_equella' : ''
    instructure_buttons += equella_button
    return instructure_buttons
  }

  /**
   * groups of buttons that are always found together, so updating a config
   * name doesn't need to happen 3 places or not work.
   * @private
   */
  formatBtnGroup =
    'bold italic underline forecolor backcolor removeformat alignleft aligncenter alignright'

  positionBtnGroup = 'outdent indent superscript subscript bullist numlist'

  fontBtnGroup = 'ltr rtl fontsizeselect formatselect check_a11y'

  /**
   * uses the width to decide how many lines of buttons to break
   * up the toolbar over.
   *
   * @private
   * @return {Array<String>} each element is a string of button names
   *   representing the buttons to appear on the n-th line of the toolbar
   */
  balanceButtons(instructure_buttons) {
    const instBtnGroup = `table media instructure_links unlink${instructure_buttons}`
    let buttons1 = ''
    let buttons2 = ''
    let buttons3 = ''

    if (this.viewportWidth < 359 && this.viewportWidth > 0) {
      buttons1 = this.formatBtnGroup
      buttons2 = `${this.positionBtnGroup} ${instBtnGroup}`
      buttons3 = this.fontBtnGroup
    } else if (this.viewportWidth < 1200) {
      buttons1 = `${this.formatBtnGroup} ${this.positionBtnGroup}`
      buttons2 = `${instBtnGroup} ${this.fontBtnGroup}`
    } else {
      buttons1 = `${this.formatBtnGroup} ${this.positionBtnGroup} ${instBtnGroup} ${this.fontBtnGroup}`
    }
    if (new_rce) {
      return [buttons1, buttons2, buttons3]
    } else {
      return [buttons1, buttons2, buttons3].map(b => b.split(' ').join(','))
    }
  }

  /**
   * builds the custom buttons, and hands them off to be munged
   * in with the core buttons and balanced across the toolbar.
   *
   * @private
   * @return {Array<String>} each element is a string of button names
   *   representing the buttons to appear on the n-th line of the toolbar
   */
  toolbar() {
    const instructure_buttons = this.buildInstructureButtons()
    return this.balanceButtons(instructure_buttons)
  }
}
