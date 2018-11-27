//
// Copyright (C) 2013 - present Instructure, Inc.
//
// This file is part of Canvas.
//
// Canvas is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, version 3 of the License.
//
// Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License along
// with this program. If not, see <http://www.gnu.org/licenses/>.

import I18n from 'i18n!editor_accessibility'
import $ from 'jquery'
import htmlEscape from 'str/htmlEscape'

// #
// Used to insert accessibility titles into core TinyMCE components
export default class EditorAccessiblity {
  constructor(editor) {
    this.editor = editor
    this.id_prepend = editor.id
    this.$el = $(`#${editor.editorContainer.id}`)
  }

  accessiblize() {
    this._cacheElements()
    this._addTitles()
    this._addLabels()
    this._accessiblizeMenubar()
    this._removeStatusbarFromTabindex()
  }

  /* PRIVATE FUNCTIONS */
  _cacheElements() {
    this.$iframe = this.$el.find('.mce-edit-area iframe')
  }

  _addLabels() {
    this.$el.attr('aria-label', I18n.t('Rich Content Editor'))
    $(this.editor.getBody()).attr('aria-label', $(`label[for="${this.id_prepend}"]`).text())
    this.$el
      .find("div[aria-label='Font Sizes']")
      .attr('aria-label', I18n.t('titles.font_size', 'Font Size, press down to select'))
    this.$el
      .find('div.mce-listbox.mce-last:not([aria-label])')
      .attr('aria-label', I18n.t('titles.formatting', 'Formatting, press down to select'))
    this.$el
      .find("div[aria-label='Text color']")
      .attr('aria-label', I18n.t('accessibles.forecolor', 'Text Color, press down to select'))
    this.$el
      .find("div[aria-label='Background color'")
      .attr(
        'aria-label',
        I18n.t('accessibles.background_color', 'Background Color, press down to select')
      )
  }

  _addTitles() {
    this.$iframe.attr('title', I18n.t('titles.rte_help', 'Rich Text Area. Press ALT+F8 for help'))
  }

  // Hide the menubar until ALT+F9 is pressed.
  _accessiblizeMenubar() {
    const $menubar = this.$el.find('.mce-menubar')
    const $firstMenu = $menubar.find('.mce-menubtn').first()
    $menubar.hide()
    this.editor.addShortcut('Alt+F9', '', () => {
      $menubar.show()
      $firstMenu.focus()
      // Once it's shown, we don't need to show it again, so replace this handler with one that just focuses.
      this.editor.addShortcut('Alt+F9', '', () => $firstMenu.focus())
    })
  }

  // keyboard only nav gets permastuck in the statusbar in FF. If you can't
  // click with a mouse, the only way out is to refresh the page.
  _removeStatusbarFromTabindex() {
    const $statusbar = this.$el.find('.mce-statusbar > .mce-container-body')
    $statusbar.attr('tabindex', -1)
  }
}
