/*
 * Copyright (C) 2011 - present Instructure, Inc.
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
import $ from 'jquery'
import 'jqueryui/dialog'

const I18n = useI18nScope('quizzes.rubric')

const quizRubric = {
  async loadBindings() {
    await import('@canvas/rubrics/jquery/rubricEditBinding') // event handler for rubricEditDataReady
  },

  async ready() {
    await this.loadBindings()
    const $dialog = $('#rubrics.rubric_dialog')
    $dialog.dialog({
      title: I18n.t('titles.details', 'Assignment Rubric Details'),
      width: 600,
      resizable: true,
      modal: true,
      zIndex: 1000,
    })
  },

  buildLoadingDialog() {
    const $loading = $('<div/>')
    $loading.text(I18n.t('loading', 'Loading...'))
    $('body').append($loading)
    $loading.dialog({
      width: 400,
      height: 200,
      modal: true,
      zIndex: 1000,
    })
    return $loading
  },

  async replaceLoadingDialog(html, $loading) {
    await this.loadBindings()
    $('body').append(html)
    $loading.dialog('close')
    $loading.remove()
    quizRubric.ready()
  },

  async createRubricDialog(url, preloadedHtml) {
    const $dialog = $('#rubrics.rubric_dialog')
    if ($dialog.length) {
      await quizRubric.ready()
    } else {
      const $loading = quizRubric.buildLoadingDialog()
      if (preloadedHtml === undefined || preloadedHtml === null) {
        const html = await $.get(url)
        await quizRubric.replaceLoadingDialog(html, $loading)
      } else {
        await quizRubric.replaceLoadingDialog(preloadedHtml, $loading)
      }
    }
  },
}

$(document).ready(function () {
  $('.show_rubric_link').click(function (event) {
    event.preventDefault()
    const url = $(this).attr('rel')
    quizRubric.createRubricDialog(url)
  })
})

export default quizRubric
