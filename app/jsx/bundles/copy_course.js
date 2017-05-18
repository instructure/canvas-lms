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

import I18n from 'i18n!content_migrations'
import $ from 'jquery'
import DateShiftView from 'compiled/views/content_migrations/subviews/DateShiftView'
import DaySubstitutionView from 'compiled/views/content_migrations/subviews/DaySubstitutionView'
import DaySubstitutionCollection from 'compiled/collections/DaySubstitutionCollection'
import CollectionView from 'compiled/views/CollectionView'
import template from 'jst/content_migrations/subviews/DaySubstitutionCollection'
import ContentMigration from 'compiled/models/ContentMigration'
import 'jquery.instructure_date_and_time'

$(document).ready(() => $('.datetime_field').datetime_field({addHiddenInput: true}))

const daySubCollection = new DaySubstitutionCollection()
const daySubCollectionView = new CollectionView({
  collection: daySubCollection,
  emptyMessage: () => I18n.t('no_day_substitutions', 'No Day Substitutions Added'),
  itemView: DaySubstitutionView,
  template
})


const dateShiftView = new DateShiftView({
  model: new ContentMigration(),
  collection: daySubCollection,
  daySubstitution: daySubCollectionView,
  oldStartDate: ENV.OLD_START_DATE,
  oldEndDate: ENV.OLD_END_DATE,
  addHiddenInput: true
})

$('#date_shift').html(dateShiftView.render().el)
dateShiftView.$oldStartDate.val(ENV.OLD_START_DATE).trigger('change')
dateShiftView.$oldEndDate.val(ENV.OLD_END_DATE).trigger('change')

const $start = $('#course_start_at')
const $end = $('#course_conclude_at')

function validateDates () {
  const startAt = $start.data('unfudged-date')
  const endAt = $end.data('unfudged-date')

  if (startAt && endAt && (endAt < startAt)) {
    $('button[type=submit]').attr('disabled', true)
    return $end.errorBox(I18n.t('End date cannot be before start date'))
  }
  $('button[type=submit]').attr('disabled', false)
  return $('#copy_course_form').hideErrors()
}

$start.on('change', function () {
  validateDates()
  dateShiftView.$newStartDate.val($(this).val()).trigger('change')
})

$end.on('change', function () {
  validateDates()
  dateShiftView.$newEndDate.val($(this).val()).trigger('change')
})
