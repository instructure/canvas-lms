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

export default class EditorConfig {
  public baseURL: string

  public extraButtons: object[]

  /**
   * Create an editor config instance, with some internal state passed in
   *   so the object knows how to generate a dynamic hash of default
   *   configuration parameters.  May get overridden by merging
   *   with another hash of overwriting config parameters.
   *
   *  @param tinymce the tinymce global which we use to pull
   *    some config info off of like the BaseURL for refrencing the skin css
   *  @param instConfig a config hash defined in public/javascripts/INST.js,
   *    provides feature information like whether notorious is enabled for
   *    their account.  Generally you can just pass it in after requiring it.
   *  @param idAttribute the "id" attribute of the element that's going
   *    to be transformed with a tinymce editor
   */
  constructor(
    tinymce: {
      baseURL: string
    },
    public readonly instConfig: any,
    public readonly idAttribute: string
  ) {
    this.baseURL = tinymce.baseURL
    this.extraButtons = instConfig.editorButtons || []
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
    return {
      body_class:
        (window.ENV.FEATURES?.canvas_k6_theme ||
          window.ENV.K5_SUBJECT_COURSE ||
          window.ENV.K5_HOMEROOM_COURSE) &&
        !window.ENV.USE_CLASSIC_FONT
          ? 'elementary-theme'
          : 'default-theme',
      selector: `#${this.idAttribute}`,
      directionality: getDirection(),
      // RCEWrapper includes instructure_equation, so it shouldn't be necessary here
      // but if I leave it out equation_spec.rb and new_ui_spec selenium specs fail
      // in jenkins (but not locally) and I can't explain why. Doesn't hurt to put it here
      plugins: ['instructure_equation'],

      content_css: window.ENV.url_to_what_gets_loaded_inside_the_tinymce_editor_css,

      init_instance_callback: (ed: {id: string}) => {
        $(`#tinymce-parent-of-${ed.id}`) // eslint-disable-line no-undef
          .css('visibility', 'visible')
      },
      // if kalturaSettings is missing, we have no kaltura to upload to
      // if present, user may have chosen to hide the button anyway.
      show_media_upload: !!INST.kalturaSettings && !INST.kalturaSettings.hide_rte_button,
    }
  }
}
