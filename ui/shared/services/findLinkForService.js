/*
 * Copyright (C) 2019 - present Instructure, Inc.
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

import I18n from 'i18n!findLinkForService'
import $ from 'jquery'
import htmlEscape from 'html-escape'
import TextHelper from '@canvas/util/TextHelper.coffee'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/forms/jquery/jquery.instructure_forms'
import 'jqueryui/dialog'

export function getUserServices(service_types, success, error) {
  if (!$.isArray(service_types)) {
    service_types = [service_types]
  }
  const url = `/services?service_types=${service_types.join(',')}`
  $.ajaxJSON(
    url,
    'GET',
    {},
    data => {
      if (success) {
        success(data)
      }
    },
    data => {
      if (error) {
        error(data)
      }
    }
  )
}

let lastLookup // used to keep track of diigo requests
export function findLinkForService(service_type, callback) {
  let $dialog = $('#instructure_bookmark_search')
  if (!$dialog.length) {
    $dialog = $("<div id='instructure_bookmark_search'/>")
    $dialog.append(
      `${"<form id='bookmark_search_form' style='margin-bottom: 5px;'>" +
        "<img src='/images/blank.png'/>&nbsp;&nbsp;" +
        "<input type='text' class='query' style='width: 230px;'/>" +
        "<button class='btn search_button' type='submit'>"}${htmlEscape(
        I18n.t('buttons.search', 'Search')
      )}</button></form>`
    )
    $dialog.append("<div class='results' style='max-height: 200px; overflow: auto;'/>")
    $dialog.find('form').submit(event => {
      event.preventDefault()
      event.stopPropagation()
      const now = new Date()
      if (service_type == 'diigo' && lastLookup && now - lastLookup < 15000) {
        // let the user know we have to take things slow because of Diigo
        setTimeout(() => {
          $dialog.find('form').submit()
        }, 15000 - (now - lastLookup))
        $dialog
          .find('.results')
          .empty()
          .append(
            htmlEscape(
              I18n.t(
                'status.diigo_search_throttling',
                'Diigo limits users to one search every ten seconds.  Please wait...'
              )
            )
          )
        return
      }
      $dialog
        .find('.results')
        .empty()
        .append(htmlEscape(I18n.t('status.searching', 'Searching...')))
      lastLookup = new Date()
      const query = $dialog.find('.query').val()
      const url = $.replaceTags($dialog.data('reference_url'), 'query', query)
      $.ajaxJSON(
        url,
        'GET',
        {},
        data => {
          $dialog.find('.results').empty()
          if (!data.length) {
            $dialog
              .find('.results')
              .append(htmlEscape(I18n.t('no_results_found', 'No Results Found')))
          }
          for (const idx in data) {
            data[idx].short_title = data[idx].title
            if (data[idx].title == data[idx].description) {
              data[idx].short_title = TextHelper.truncateText(data[idx].description, {max: 30})
            }
            $("<div class='bookmark'/>")
              .appendTo($dialog.find('.results'))
              .append(
                $('<a class="bookmark_link" style="font-weight: bold;"/>')
                  .attr({
                    href: data[idx].url,
                    title: data[idx].title
                  })
                  .text(data[idx].short_title)
              )
              .append(
                $("<div style='margin: 5px 10px; font-size: 0.8em;'/>").text(
                  data[idx].description || I18n.t('no_description', 'No description')
                )
              )
          }
        },
        () => {
          $dialog
            .find('.results')
            .empty()
            .append(htmlEscape(I18n.t('errors.search_failed', 'Search failed, please try again.')))
        }
      )
    })
    $dialog.delegate('.bookmark_link', 'click', function(event) {
      event.preventDefault()
      const url = $(this).attr('href')
      const title = $(this).attr('title') || $(this).text()
      $dialog.dialog('close')
      callback({
        url,
        title
      })
    })
  }
  $dialog
    .find('.search_button')
    .text(
      service_type == 'delicious'
        ? I18n.t('buttons.search_by_tag', 'Search by Tag')
        : I18n.t('buttons.search', 'Search')
    )
  $dialog.find('form img').attr('src', `/images/${service_type}_small_icon.png`)
  let url = '/search/bookmarks?q=%7B%7B+query+%7D%7D&service_type=%7B%7B+service_type+%7D%7D'
  url = $.replaceTags(url, 'service_type', service_type)
  $dialog.data('reference_url', url)
  $dialog
    .find('.results')
    .empty()
    .end()
    .find('.query')
    .val('')
  $dialog.dialog({
    title: I18n.t('titles.bookmark_search', 'Bookmark Search: %{service_name}', {
      service_name: $.titleize(service_type)
    }),
    open() {
      $dialog
        .find('input:visible:first')
        .focus()
        .select()
    },
    width: 400
  })
}
