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
import ready from '@instructure/ready'
import DateShiftView from '@canvas/content-migrations/backbone/views/DateShiftView'
import DaySubstitutionView from '@canvas/day-substitution/backbone/views/DaySubstitutionView'
import ImportQuizzesNextView from '@canvas/content-migrations/backbone/views/ImportQuizzesNextView'
import DaySubstitutionCollection from '@canvas/day-substitution/backbone/collections/DaySubstitutionCollection'
import CollectionView from '@canvas/backbone-collection-view'
import template from '@canvas/day-substitution/jst/DaySubstitutionCollection.handlebars'
import ContentMigration from '@canvas/content-migrations/backbone/models/ContentMigration'
import '@canvas/datetime/jquery'

const I18n = useI18nScope('content_migrations')

ready(() => {
  $(document).ready(() => $('.datetime_field').datetime_field({addHiddenInput: true}))

  const daySubCollection = new DaySubstitutionCollection()
  const daySubCollectionView = new CollectionView({
    collection: daySubCollection,
    emptyMessage: () => I18n.t('no_day_substitutions', 'No Day Substitutions Added'),
    itemView: DaySubstitutionView,
    template,
  })

  const content_migration = new ContentMigration()

  const dateShiftView = new DateShiftView({
    model: content_migration,
    collection: daySubCollection,
    daySubstitution: daySubCollectionView,
    oldStartDate: ENV.OLD_START_DATE,
    oldEndDate: ENV.OLD_END_DATE,
    addHiddenInput: true,
  })

  const importQuizzesNextView = new ImportQuizzesNextView({
    model: content_migration,
    quizzesNextEnabled: ENV.QUIZZES_NEXT_ENABLED,
    migrationDefault: ENV.NEW_QUIZZES_MIGRATION_DEFAULT,
    questionBank: null,
  })
  $('#new_quizzes_migrate').html(importQuizzesNextView.render().el)
  $('#importQuizzesNext').attr('name', 'settings[import_quizzes_next]')

  $('#date_shift').html(dateShiftView.render().el)
  dateShiftView.$oldStartDate.val(ENV.OLD_START_DATE).trigger('change')
  dateShiftView.$oldEndDate.val(ENV.OLD_END_DATE).trigger('change')

  const $start = $('#course_start_at')
  const $end = $('#course_conclude_at')

  function validateDates() {
    const startAt = $start.data('unfudged-date')
    const endAt = $end.data('unfudged-date')

    if (startAt && endAt && endAt < startAt) {
      $('button[type=submit]').prop('disabled', true)
      return $end.errorBox(I18n.t('End date cannot be before start date'))
    }
    $('button[type=submit]').prop('disabled', false)
    return $('#copy_course_form').hideErrors()
  }

  $start.on('change', function () {
    dateShiftView.$newStartDate.val($(this).val()).trigger('change')
    validateDates()
  })

  $end.on('change', function () {
    dateShiftView.$newEndDate.val($(this).val()).trigger('change')
    validateDates()
  })

  if (document.querySelector('.import-blueprint-settings')) {
    $('[name="selective_import"]').change(function () {
      const ibs = document.querySelector('.import-blueprint-settings')
      ibs.style.display = this.value === 'true' ? 'none' : 'block'
    })
  }
})
