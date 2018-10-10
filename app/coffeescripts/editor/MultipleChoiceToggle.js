#
# Copyright (C) 2012 - present Instructure, Inc.
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

define [
  'jquery',
  'str/htmlEscape',
  '../editor/EditorToggle',
  'jsx/shared/rce/RceCommandShim'
  ], ($, htmlEscape, EditorToggle, RceCommandShim) ->

  ##
  # Toggles a multiple choice quiz answer between an editor and an element
  class MultipleChoiceToggle extends EditorToggle

    ##
    # @param {jQuery} @editButton - the edit button to trigger the toggle
    # @param {Object} options - options for EditorToggle
    # @api public
    constructor: (@editButton, options) ->
      @cacheElements()
      super @answer.find('.answer_html'), options

    ##
    # Finds all the relevant elements from the perspective of the edit button
    # that toggles the element between itself and an editor
    # @api private
    cacheElements: ->
      @answer = @editButton.parents '.answer'
      @answerText = @answer.find 'input[name=answer_text]'
      @answerText.hide()
      @input = @answer.find 'input[name=answer_html]'

    ##
    # Extends EditorToggle::display to @toggleIfEmpty and sets the hidden
    # input's value to the content from the editor
    # @api public
    display: ->
      super
      @toggleIfEmpty()
      @input.val @content
      @answerText.val '' if @content is ''

    ##
    # Extends EditorToggle::edit to always hide the original input
    # in case it was shown because the editor content was empty
    # @api public
    edit: ->
      super
      id = @textArea.attr('id')
      @answerText.hide()
      if @content is ''
        RceCommandShim.send(@textArea, 'set_code', htmlEscape(@answerText.val()))
      else
        RceCommandShim.send(@textArea, 'set_code', @content)

    ##
    # Shows the original <input type=text> that the editor replaces and hides
    # the HTML display element, also sets @input value to '' so the quizzes.js
    # hooks don't think its an html answer
    # @api public
    showAnswerText: ->
      @answerText.show()
      @el.hide()
      @input.val ''

    ##
    # Shows the HTML element and hides the origina input
    # @api public
    showEl: ->
      @answerText.hide()
      @el.show()

    ##
    # If the editor has no content, it will show the original input
    # @api public
    toggleIfEmpty: ->
      if @isEmpty() then @showAnswerText() else @showEl()

    ##
    # Determines if the editor has any content
    # @returns {Boolean}
    # @api private
    isEmpty: ->
      $.trim(@content) is ''
