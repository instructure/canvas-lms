/*
 * Copyright (C) 2023 - present Instructure, Inc.
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

import {extend} from '@canvas/backbone/utils'
import {useScope as createI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {View} from '@canvas/backbone'
import template from '../../jst/newConference.handlebars'
import '@canvas/rails-flash-notifications'
import authenticity_token from '@canvas/authenticity-token'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import ReactDOM from 'react-dom'
import React from 'react'
import '@canvas/jquery/jquery.instructure_forms'
import {initializeTopNavPortalWithDefaults} from '@canvas/top-navigation/react/TopNavPortalWithDefaults'

const I18n = createI18nScope('conferences')

// @ts-expect-error TS2345 (typescriptify)
extend(ConferenceView, View)

// @ts-expect-error TS7023 (typescriptify)
function ConferenceView() {
  // @ts-expect-error TS2683 (typescriptify)
  this.updateConferenceDetails = this.updateConferenceDetails.bind(this)
  // @ts-expect-error TS2683 (typescriptify)
  this.removeRecordingRow = this.removeRecordingRow.bind(this)
  // @ts-expect-error TS2339,TS2683 (typescriptify)
  return ConferenceView.__super__.constructor.apply(this, arguments)
}

ConferenceView.prototype.tagName = 'li'

ConferenceView.prototype.className = 'conference'

ConferenceView.prototype.template = template

ConferenceView.prototype.events = {
  'click .edit_conference_link': 'edit',
  'click .delete_conference_link': 'delete',
  'click .close_conference_link': 'close',
  'click .start-button': 'start',
  'click .delete_recording_link': 'deleteRecording',
}

ConferenceView.prototype.initialize = function () {
  // @ts-expect-error TS2339 (typescriptify)
  ConferenceView.__super__.initialize.apply(this, arguments)

  // @ts-expect-error TS7031 (typescriptify)
  const handleBreadCrumbSetter = ({getCrumbs, setCrumbs}) => {
    const currentCrumbs = getCrumbs()
    currentCrumbs.at(-1).url = ''
    setCrumbs(currentCrumbs)
  }

  initializeTopNavPortalWithDefaults({
    getBreadCrumbSetter: handleBreadCrumbSetter,
  })

  return this.model.on('change', this.render)
}

// @ts-expect-error TS7006 (typescriptify)
ConferenceView.prototype.edit = function (_e) {
  // refocus if edit not finalized
  return this.$el.find('.al-trigger').focus()
}

ConferenceView.prototype.toJSON = function () {
  // @ts-expect-error TS2339 (typescriptify)
  const json = ConferenceView.__super__.toJSON.apply(this, arguments)
  json.auth_token = authenticity_token()
  return json
}

// @ts-expect-error TS7006 (typescriptify)
ConferenceView.prototype.delete = function (e) {
  let allCogs, curIndex, currentCog
  e.preventDefault()
  if (
    !window.confirm(I18n.t('confirm.delete', 'Are you sure you want to delete this conference?'))
  ) {
    return $(e.currentTarget).parents('.inline-block').find('.al-trigger').focus()
  } else {
    currentCog = $(e.currentTarget).parents('.inline-block').find('.al-trigger')[0]
    allCogs = $('#content .al-trigger').toArray()
    curIndex = allCogs.indexOf(currentCog)
    if (curIndex > 0) {
      allCogs[curIndex - 1].focus()
    } else {
      $('.new-conference-btn').focus()
    }
    return this.model.destroy({
      success: (function (_this) {
        return function () {
          return $.screenReaderFlashMessage(I18n.t('Conference was deleted'))
        }
      })(this),
    })
  }
}

// @ts-expect-error TS7006 (typescriptify)
ConferenceView.prototype.close = function (e) {
  e.preventDefault()
  if (
    !window.confirm(
      I18n.t(
        'confirm.close',
        'Are you sure you want to end this conference?\n\nYou will not be able to reopen it.',
      ),
    )
  ) {
    return
  }
  return $.ajaxJSON(
    $(e.currentTarget).attr('href'),
    'POST',
    {},
    (function (_this) {
      // @ts-expect-error TS7006 (typescriptify)
      return function (_data) {
        // @ts-expect-error TS2339 (typescriptify)
        return window.router.close(_this.model)
      }
    })(this),
  )
}

// @ts-expect-error TS7006 (typescriptify)
ConferenceView.prototype.start = function (e) {
  // @ts-expect-error TS7034 (typescriptify)
  let i
  if (this.model.isNew()) {
    e.preventDefault()
    return
  }
  const w = window.open(e.currentTarget.href, '_blank')
  if (!w) {
    return
  }
  e.preventDefault()
  w.onload = function () {
    // @ts-expect-error TS2554 (typescriptify)
    return window.location.reload(true)
  }
  // cross-domain
  return (i = setInterval(function () {
    if (!w) {
      return
    }
    try {
      return w.location.href
    } catch (error) {
      e = error
      // @ts-expect-error TS7005 (typescriptify)
      clearInterval(i)
      // @ts-expect-error TS2554 (typescriptify)
      return window.location.reload(true)
    }
  }, 100))
}

// @ts-expect-error TS7006 (typescriptify)
ConferenceView.prototype.deleteRecording = function (e) {
  // @ts-expect-error TS7034 (typescriptify)
  let $button
  e.preventDefault()

  if (window.confirm(I18n.t('Are you sure you want to delete this recording?'))) {
    $button = $(e.currentTarget).parents('div.ig-button')
    return $.ajaxJSON($button.data('url') + '/recording', 'DELETE', {
      recording_id: $button.data('id'),
    })
      .done(
        (function (_this) {
          // @ts-expect-error TS7006 (typescriptify)
          return function (data, _status) {
            if (data.deleted) {
              // @ts-expect-error TS7005 (typescriptify)
              return _this.removeRecordingRow($button)
            }
            return $.flashError(
              I18n.t('Sorry, the action performed on this recording failed. Try again later'),
            )
          }
        })(this),
      )
      .fail(
        (function (_this) {
          // @ts-expect-error TS7006 (typescriptify)
          return function (_xhr, _status) {
            return $.flashError(
              I18n.t('Sorry, the action performed on this recording failed. Try again later'),
            )
          }
        })(this),
      )
  }
}

// @ts-expect-error TS7006 (typescriptify)
ConferenceView.prototype.removeRecordingRow = function ($button) {
  const $row = $('.ig-row[data-id="' + $button.data('id') + '"]')
  const $conferenceId = $($row.parents('div.ig-sublist')).data('id')
  $row.parents('li.recording').remove()
  this.updateConferenceDetails($conferenceId)
  return $.screenReaderFlashMessage(I18n.t('Recording was deleted'))
}

// @ts-expect-error TS7006 (typescriptify)
ConferenceView.prototype.updateConferenceDetails = function (id) {
  const $info = $('div.ig-row#conf_' + id).find('div.ig-info')
  const $detailRecordings = $info.find('div.ig-details__item-recordings')
  const $recordings = $('.ig-sublist#conference-' + id)
  const recordings = $recordings.find('li.recording').length
  if (recordings > 1) {
    $detailRecordings.text(
      I18n.t('%{count} Recordings', {
        count: recordings,
      }),
    )
    return
  }
  if (recordings === 1) {
    $detailRecordings.text(
      I18n.t('%{count} Recording', {
        count: 1,
      }),
    )
    return
  }
  $detailRecordings.remove()
  $recordings.remove()
  // Shift the link to text
  const $link = $info.children('a.ig-title')
  const $text = $('<span />').addClass('ig-title').html($link.text())
  $info.prepend($text)
  return $link.remove()
}

export default ConferenceView
