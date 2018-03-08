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

import I18n from 'i18n!quizzes.timing'
import $ from 'jquery'

export default function addAriaDescription($answer, id) {
  const text = I18n.t('Answer %{answerId}', {answerId: id})
  const labelId = `answer${id}`

  const $label = $('<label/>', {
    id: labelId,
    class: 'screenreader-only',
    text
  })

  $answer.find('input:text').attr('aria-describedby', labelId)
  $answer.find('.deleteAnswerId').text(text)
  $answer.find('.editAnswerId').text(text)
  $answer.find('.commentAnswerId').text(text)
  $answer.find('.selectAsCorrectAnswerId').text(text)

  $answer.prepend($label)
}
