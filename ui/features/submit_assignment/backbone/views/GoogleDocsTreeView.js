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

import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import template from '../../jst/googleDocsTreeView.handlebars'
import '@canvas/jquery/jquery.tree'

const I18n = useI18nScope('titles')

class GoogleDocsTreeView extends Backbone.View {
  constructor(...args) {
    super(...args)
    this.handleKeyboard = this.handleKeyboard.bind(this)
    this.activateFile = this.activateFile.bind(this)
    this.activateFolder = this.activateFolder.bind(this)
  }

  render() {
    const title_text = I18n.t('view_in_separate_window', 'View in Separate Window')

    this.$el.html(this.template({tree: this.model, title_text}))

    return this.$el.instTree({
      autoclose: false,
      multi: false,
      dragdrop: false,
    })
  }

  handleKeyboard(ev) {
    if (ev.keyCode === 32) {
      // When the spacebar is pressed
      if ($(document.activeElement).hasClass('file')) return this.activateFile(ev)
      if ($(document.activeElement).hasClass('folder')) return this.activateFolder(ev)
    }
  }

  activateFile(event) {
    let $target
    if (this.$(event.target).closest('.popout').length > 0) return

    if (event.type === 'keydown') {
      $target = this.$(event.target)
    } else {
      $target = this.$(event.currentTarget)
    }

    event.preventDefault()
    event.stopPropagation()
    this.$('.file.active').removeClass('active')
    $target.addClass('active')
    const file_id = $target.attr('id').substring(9)
    this.trigger('activate-file', file_id)
    return $('#submit_google_doc_form .btn-primary').focus()
  }

  activateFolder(event) {
    let $target, folder
    if (event.type === 'keydown') {
      event.preventDefault()
      $target = this.$(event.target).find('.sign')
      folder = this.$(event.target)
    } else {
      $target = this.$(event.target)
      if ($target.closest('.sign').length === 0) {
        folder = this.$(event.currentTarget)
      }
    }

    if (folder && $target.closest('.file,.folder').hasClass('folder')) {
      folder.find('.sign').click()
      return folder.find('.file').focus()
    }
  }
}

GoogleDocsTreeView.prototype.template = template

GoogleDocsTreeView.prototype.events = {
  'click li.file': 'activateFile',
  'click li.folder': 'activateFolder',
  keydown: 'handleKeyboard',
}

GoogleDocsTreeView.prototype.tagName = 'ul'
GoogleDocsTreeView.prototype.id = 'google_docs_tree'
GoogleDocsTreeView.prototype.attributes = {style: 'width: 100%;'}

export default GoogleDocsTreeView
