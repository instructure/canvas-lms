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

import I18n from 'i18n!accounts.statistics'
import $ from 'jquery'
import './jquery.ajaxJSON'
import 'jqueryui/dialog'
import './jquery.instructure_misc_helpers' // replaceTags

function populateDialog (data_points, axis, $link) {
  $('#over_time_dialog').dialog({
    width: 630,
    height: 330,
    title: I18n.t('%{data_point} Over Time', {data_point: axis}),
    close: () => {
      $link.focus()
    }
  })

  // google dependencies declared in views/acccounts/statistics since google.load uses document.write :(
  /* global google */
  const data = new google.visualization.DataTable();
  data.addColumn('date', I18n.t('Date'))
  data.addColumn('number', axis || I18n.t('Value'))
  data.addColumn('string', 'title1');
  data.addColumn('string', 'text1');

  const rows = []
  $.each(data_points, function() {
    const date = new Date()
    date.setTime(this[0])
    rows.push(
      // this ends up being [(a date), (the number of pageViews on that date), "an annotation tile, (if any)", ""]
      [date, this[1], undefined, undefined]
    )
  })

  data.addRows(rows)

  const chart = new google.visualization.AnnotatedTimeLine(document.getElementById('over_time'))
  chart.draw(data, {displayAnnotations: false})
}

$(document).ready(() => {
  $('.over_time_link').live('click', function (event) {
    event.preventDefault()
    const $link = $(this)
    const name = $link.attr('data-name')
    const url = $.replaceTags($('.over_time_url').attr('href'), 'attribute', $link.attr('data-key'))
    $link.text(I18n.t('loading...'))
    $.ajaxJSON(url, 'GET', {}, (data) => {
      $link.text(I18n.t('over time'))
      $('#over_time_dialog .csv_url').attr('href', `${url}.csv`)
      populateDialog(data, name, $link)
    }, () => {
      $link.text(I18n.t('error'))
    })
  })
})
