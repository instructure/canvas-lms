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

import I18n from 'i18n!ExternalToolsPlugin'
import htmlEscape from '../../str/htmlEscape'
import '../../jquery.dropdownList'
import '../../jquery.instructure_misc_helpers'

// setting ENV.MAX_MRU_LTI_TOOLS can make it easier to test
const MAX_MRU_LTI_TOOLS = ENV.MAX_MRU_LTI_TOOLS || 5

/**
 * A module for holding helper functions pulled out of the instructure_external_tools/plugin.
 *
 * This should make it easy to seperate and test logic as this evolves
 * without splitting out another module, and since the plugin gets
 * registered with tinymce rather than returned, we can return this
 * object at the end of the module definition as an export for unit testing.
 *
 * @exports
 */

export default {
  /**
   * build the TinyMCE configuration hash for each
   * LTI button.  Call once for each button to add
   * to the toolbar
   *
   * the "widget" and "btn" classes are what tinymce
   * provides by default and the theme makes use of them,
   * if you don't include them than our custom class
   * overwrites the default classes and all the styles break
   *
   * @param {Hash (representing a button)} button a collection of name, id,
   *   icon_url to use for building the right config for an external plugin
   *
   * @returns {Hash} appropriate configuration for a tinymce addButton call,
   *   complete with title, cmd, image, and classes
   */
  buttonConfig(button, editor) {
    const config = {
      title: button.name,
      classes: 'widget btn instructure_external_tool_button'
    }
    if (ENV.use_rce_enhancements) {
      config.id = button.id
      config.onAction = () => {
        editor.execCommand(`instructureExternalButton${button.id}`)
        this.updateMRUList(button.id)
        this.showHideButtons(editor)
      }
      config.description = button.description
      config.favorite = button.favorite
    } else {
      config.cmd = `instructureExternalButton${button.id}`
    }

    if (button.canvas_icon_class) {
      config.icon = `hack-to-avoid-mce-prefix ${button.canvas_icon_class}`
    } else {
      // default to image
      config.image = button.icon_url
    }

    return config
  },

  /**
   * convert the button clump configuration to
   * an associative array where the key is an image tag
   * with the name and the value is the thing to do
   * when that button gets clicked.  This gives us
   * a decent structure for mapping click events for
   * each dynamically generated button in the button clump
   * list.
   *
   * @param {Array<Hash (representing a button)>} clumpedButtons an array of
   *   button configs, like the ones passed into "buttonConfig"
   *   above as parameters
   *
   * @param {function(Hash), editor} onClickHandler the function that should get
   *   called when this button gets clicked
   *
   * @returns {Hash<string,function(Hash)>} the hash we can use
   *   for generating a dropdown list in jquery
   */
  clumpedButtonMapping(clumpedButtons, ed, onClickHandler) {
    return clumpedButtons.reduce((items, button) => {
      let key

      // added  data-tool-id='"+ button.id +"' to make elements unique when the have the same name
      if (button.canvas_icon_class) {
        key = `<i class='${htmlEscape(button.canvas_icon_class)}' data-tool-id='${button.id}'></i>`
      } else {
        // icon_url is implied
        key = `<img src='${htmlEscape(button.icon_url)}' data-tool-id='${button.id}'/>`
      }
      key += `&nbsp;${htmlEscape(button.name)}`
      items[key] = function() {
        onClickHandler(button, ed)
      }
      return items
    }, {})
  },

  /**
   * extend the dropdown menu for all the buttons
   * clumped up into the "externalButtonClump", and attach
   * an event to the editor so that whenever you click
   * anywhere else on the editor the dropdown goes away.
   *
   * @param {jQuery Object} target the Dom element we're attaching
   *   this dropdown list to
   * @param {Hash<string,function(Hash)>} buttons the buttons to put
   *   into the dropdown list, typically generated from 'clumpedButtonMapping'
   * @param {tinymce.Editor} editor the relevant editor for this
   *   dropdown list, to whom we will listen for any click events
   *   outside the dropdown menu
   */
  attachClumpedDropdown(target, buttons, editor) {
    target.dropdownList({options: buttons})
    editor.on('click', () => {
      target.dropdownList('hide')
    })
  },

  showHideButtons(ed) {
    const label = I18n.t('Apps')
    if (window.localStorage?.getItem('ltimru')) {
      ed.$(ed.editorContainer.querySelector(`.tox-tbtn--select[aria-label="${label}"]`)).show()
      ed.$(ed.editorContainer.querySelector(`.tox-tbtn[aria-label="${label}"]`)).hide()
    } else {
      ed.$(ed.editorContainer.querySelector(`.tox-tbtn--select[aria-label="${label}"]`)).hide()
      ed.$(ed.editorContainer.querySelector(`.tox-tbtn[aria-label="${label}"]`)).show()
    }
  },

  updateMRUList(toolId) {
    let mrulist
    try {
      mrulist = JSON.parse(window.localStorage?.getItem('ltimru') || '[]')
    } catch (ex) {
      // eslint-disable-next-line no-console
      console.log('Found bad LTI MRU data', ex.message)
    } finally {
      if (!Array.isArray(mrulist)) {
        mrulist = []
      }
    }
    try {
      if (!mrulist.includes(toolId)) {
        mrulist.unshift(toolId)
        mrulist.splice(MAX_MRU_LTI_TOOLS, mrulist.length)
        window.localStorage?.setItem('ltimru', JSON.stringify(mrulist))
      }
    } catch (ex) {
      // swallow it
      // eslint-disable-next-line no-console
      console.log('Cannot save LTI MRU list', ex.message)
    }
  }
}
