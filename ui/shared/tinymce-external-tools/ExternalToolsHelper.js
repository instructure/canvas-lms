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

import {useScope as useI18nScope} from '@canvas/i18n'

const I18n = useI18nScope('ExternalToolsPlugin')

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
    config.id = button.id
    config.onAction = () => {
      editor.execCommand(`instructureExternalButton${button.id}`)
      this.updateMRUList(button.id)
      this.showHideButtons(editor)
    }
    config.description = button.description
    config.favorite = button.favorite
    config.image = button.icon_url

    return config
  },

  showHideButtons(ed) {
    const label = I18n.t('Apps')
    const menubutton = ed.$(
      ed.editorContainer.querySelector(`.tox-tbtn--select[aria-label="${label}"]`)
    )
    const button = ed.$(ed.editorContainer.querySelector(`.tox-tbtn[aria-label="${label}"]`))
    menubutton.attr('aria-hidden', 'false')
    button.attr('aria-hidden', 'true')
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
