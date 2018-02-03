/*
 * Copyright (C) 2016 - present Instructure, Inc.
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

import I18n from 'i18n!question_bank'
import $ from 'jquery'
import moveQuestionTemplate from 'jst/quiz/move_question'
import htmlEscape from 'str/htmlEscape'
import loadBanks from '../../quizzes/question_bank/loadBanks'
import 'jquery.ajaxJSON'
import 'jquery.instructure_forms' /* formSubmit, getFormData, formErrors */
import 'jqueryui/dialog'
import 'jquery.instructure_misc_helpers' /* replaceTags */
import 'jquery.instructure_misc_plugins' /* confirmDelete, showIf, .dim */
import 'jquery.keycodes' /* keycodes */
import 'jquery.loadingImg' /* loadingImage */
import 'jquery.templateData' /* fillTemplateData, getTemplateData */

  var moveQuestions = {
    elements: {
      $dialog: () => {return $('#move_question_dialog')},
      $loadMessage: $('<li />').append(htmlEscape(I18n.t('load_questions', 'Loading Questions...'))),
      $questions: $('#move_question_dialog .questions')
    },
    messages: {
      move_copy_questions: I18n.t('title.move_copy_questions', "Move/Copy Questions"),
      move_questions: I18n.t('move_questions', 'Move Questions'),
      multiple_questions: I18n.t('multiple_questions', 'Multiple Questions')
    },
    page: 1,
    addEvents: function(){
      $('.move_questions_link').bind('click.moveQuestions', $.proxy(this.onClick, this))
      return this
    },
    onClick: function(e){
      e.preventDefault()
      this.prepDialog()
      this.showDialog()
      this.loadData()
      this.elements
        .$dialog()
        .parent()
        .find('.ui-dialog-titlebar-close')[0]
        .focus()
    },
    prepDialog: function(){
      this.elements.$dialog().find('.question_text').hide()
      this.elements.$questions.show()
      this.elements.$questions.find('.list_question:not(.blank)').remove()
      this.elements.$dialog().find('.question_name').text(this.messages.multiple_questions)
      this.elements.$dialog().find('.copy_option').hide().find(':checkbox').attr('checked', false)
      this.elements.$dialog().find('.submit_button').text(this.messages.move_questions)
      this.elements.$dialog().find('.multiple_questions').val('1')
      this.elements.$dialog().data('question', null)
    },
    showDialog: function(){
      if (!this.elements.$dialog().hasClass('loaded')){
        loadBanks(this.elements.$dialog())
      } else {
        this.elements.$dialog().find('li message').hide()
      }

      this.elements.$dialog().dialog({
        title: this.messages.move_copy_questions,
        width: 600
      })
    },
    loadData: function(){
      this.elements.$questions.append(this.elements.$loadMessage)
      $.ajaxJSON(window.location.href + '/questions?page=' + this.page, 'GET', {}, $.proxy(this.onData, this))
    },
    onData: function(data){
      const html = moveQuestionTemplate(data)
      this.elements.$loadMessage.remove()
      this.elements.$questions.append(html)
      if (this.page < data.pages){
        this.elements.$questions.append(this.elements.$loadMessage)
        this.page += 1
        this.loadData()
      } else {
        this.page = 1
      }
    }
  }

export default moveQuestions
