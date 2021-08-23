#
# Copyright (C) 2013 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import I18n from 'i18n!titles'
import $ from 'jquery'
import Backbone from '@canvas/backbone'
import template from '../../jst/googleDocsTreeView.handlebars'
import 'jquery-tree'

export default class GoogleDocsTreeView extends Backbone.View

  template: template

  events:
    "click li.file": "activateFile",
    "click li.folder": "activateFolder",
    "keydown": "handleKeyboard",

  render: ()->
    title_text = I18n.t('view_in_separate_window', "View in Separate Window")

    @$el.html @template({tree: @model, title_text: title_text})

    @$el.instTree
      autoclose: false,
      multi: false,
      dragdrop: false

  handleKeyboard: (ev)=>
    if (ev.keyCode == 32) # When the spacebar is pressed
      if $(document.activeElement).hasClass("file")
        this.activateFile(ev)
      else if $(document.activeElement).hasClass("folder")
        this.activateFolder(ev)

  activateFile: (event)=>
    return if @$(event.target).closest(".popout").length > 0

    if event.type == "keydown"
      $target = @$(event.target)
    else
      $target = @$(event.currentTarget)

    event.preventDefault()
    event.stopPropagation()
    @$(".file.active").removeClass 'active'
    $target.addClass 'active'
    file_id = $target.attr('id').substring(9)
    @trigger('activate-file', file_id)
    $("#submit_google_doc_form .btn-primary").focus()

  activateFolder: (event)=>
    if event.type == "keydown"
      event.preventDefault()
      $target = @$(event.target).find(".sign")
      folder  = @$(event.target)
    else
      $target = @$(event.target)
      if $target.closest('.sign').length == 0
        folder = @$(event.currentTarget)

    if folder && $target.closest('.file,.folder').hasClass('folder')
      folder.find(".sign").click()
      folder.find(".file").focus()

  tagName: 'ul'

  id: 'google_docs_tree'

  attributes:
    style: 'width: 100%;'
