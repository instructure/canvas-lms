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

import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import '@canvas/jquery/jquery.ajaxJSON'
import 'jqueryui/dialog'
import replaceTags from '@canvas/util/replaceTags'
import {initializeTopNavPortal} from '@canvas/top-navigation/react/TopNavPortal'

const I18n = createI18nScope('accounts.statistics')

function focusAndAddAriaAttributesToCloseButton() {
  const closeButton = $('.ui-dialog-titlebar-close')
  closeButton.attr('role', 'button')
  closeButton.focus()
}

function addAriaAttributesToDialog() {
  const dialog = $('.ui-dialog')

  if (!dialog.attr('aria-modal')) {
    dialog.attr('aria-modal', 'true')
  }
}

function updateChartAriaLabels(label) {
  const chartContainer = $(
    '#over_time_AnnotationChart_chartContainer > div > div > div, #over_time_AnnotationChart_chartContainer svg, #over_time_AnnotationChart_rangeControlContainer > div > div > div, #over_time_AnnotationChart_rangeControlContainer svg',
  )
  chartContainer.removeAttr('aria-label')

  const chart = $('#over_time_AnnotationChart_chartContainer > div > div > div > div')
  chart.attr('aria-label', label)
}

function populateDialog(data_points, axis, $link) {
  $('#over_time_dialog').dialog({
    width: 630,
    height: 330,
    title: I18n.t('%{data_point} Over Time', {data_point: axis}),
    close: () => {
      $link.focus()
    },
    modal: true,
    zIndex: 1000,
    open: () => {
      focusAndAddAriaAttributesToCloseButton()
      addAriaAttributesToDialog()
    },
  })

  // google dependencies declared in views/acccounts/statistics since google.load uses document.write :(
  /* global google */
  const data = new google.visualization.DataTable()
  data.addColumn('date', I18n.t('Date'))
  data.addColumn('number', axis || I18n.t('Value'))
  data.addColumn('string', 'title1')
  data.addColumn('string', 'text1')

  const rows = []
  $.each(data_points, function () {
    const date = new Date()
    date.setTime(this[0])
    rows.push(
      // this ends up being [(a date), (the number of pageViews on that date), "an annotation tile, (if any)", ""]
      [date, this[1], undefined, undefined],
    )
  })

  data.addRows(rows)

  const chart = new google.visualization.AnnotatedTimeLine(document.getElementById('over_time'))
  chart.draw(data, {displayAnnotations: false})

  const checkInterval = setInterval(function () {
    const chart = $('#over_time_AnnotationChart_chartContainer')

    // Check if the chart has been drawn
    if (chart.length) {
      const label = I18n.t('Graph of %{data_point} Over Time', {data_point: axis})
      updateChartAriaLabels(label)

      clearInterval(checkInterval)
    }
  }, 100)
}

$(document).ready(() => {
  initializeTopNavPortal()
  $(document).on('click', '.over_time_link', function (event) {
    event.preventDefault()
    const $link = $(this)
    const name = $link.attr('data-name')
    const url = replaceTags($('.over_time_url').attr('href'), 'attribute', $link.attr('data-key'))
    $link.text(I18n.t('loading...'))
    $.ajaxJSON(
      url,
      'GET',
      {},
      data => {
        $link.text(I18n.t('over time'))
        $('#over_time_dialog .csv_url').attr('href', `${url}.csv`)
        populateDialog(data, name, $link)
      },
      () => {
        $link.text(I18n.t('error'))
      },
    )
  })
})
