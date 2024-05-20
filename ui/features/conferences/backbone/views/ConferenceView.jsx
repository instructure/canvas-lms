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

/* eslint-disable no-void */

import {extend} from '@canvas/backbone/utils'
import {useScope as useI18nScope} from '@canvas/i18n'
import $ from 'jquery'
import {View} from '@canvas/backbone'
import template from '../../jst/newConference.handlebars'
import '@canvas/rails-flash-notifications'
import authenticity_token from '@canvas/authenticity-token'
import {Spinner} from '@instructure/ui-spinner'
import {Text} from '@instructure/ui-text'
import ReactDOM from 'react-dom'
import React from 'react'
import '@canvas/jquery/jquery.instructure_forms' // formSubmit

const I18n = useI18nScope('conferences')

extend(ConferenceView, View)

function ConferenceView() {
  this.updateConferenceDetails = this.updateConferenceDetails.bind(this)
  this.removeRecordingRow = this.removeRecordingRow.bind(this)
  return ConferenceView.__super__.constructor.apply(this, arguments)
}

ConferenceView.prototype.tagName = 'li'

ConferenceView.prototype.className = 'conference'

ConferenceView.prototype.template = template

ConferenceView.prototype.events = {
  'click .edit_conference_link': 'edit',
  'click .sync_conference_link': 'syncAttendees',
  'click .delete_conference_link': 'delete',
  'click .close_conference_link': 'close',
  'click .start-button': 'start',
  'click .external_url': 'external',
  'click .delete_recording_link': 'deleteRecording',
}

ConferenceView.prototype.initialize = function () {
  ConferenceView.__super__.initialize.apply(this, arguments)
  return this.model.on('change', this.render)
}

ConferenceView.prototype.syncAttendees = function (e) {
  let ref, ref1
  if ((ref = this.el.querySelector("a[data-testid='settings-cog']")) != null) {
    ref.classList.add('ui-state-disabled')
  }
  if ((ref1 = this.el.querySelector("a[data-testid='start-button']")) != null) {
    ref1.setAttribute('disabled', '')
  }
  const atag = e.target
  const form = atag.parentElement.querySelector('form')
  const conference_name = form.querySelector("[name='web_conference[title]']").value || ''
  const spinner = React.createElement(Spinner, {
    renderTitle: 'Loading',
    size: 'x-small',
  })
  const spinnerText = React.createElement(
    Text,
    {
      size: 'small',
    },
    I18n.t(' Attendee sync in progress... ')
  )
  const spinnerDomEl = this.el.querySelector('.conference-loading-indicator')
  ReactDOM.render([spinner, spinnerText], spinnerDomEl)
  this.el.querySelector('.conference-loading-indicator').style.display = 'block'
  this.$(form).formSubmit({
    object_name: 'web_conference',
    success: (function (_this) {
      return function (data) {
        let ref2, ref3
        _this.model.set(data)
        _this.model.trigger('sync')
        _this.el.querySelector('.conference-loading-indicator').style.display = 'none'
        ReactDOM.unmountComponentAtNode(spinnerDomEl)
        $.flashMessage(conference_name + I18n.t(' Attendees Synced!'))
        if ((ref2 = _this.el.querySelector("a[data-testid='settings-cog']")) != null) {
          ref2.classList.remove('ui-state-disabled')
        }
        return (ref3 = _this.el.querySelector("a[data-testid='start-button']")) != null
          ? ref3.removeAttribute('disabled')
          : void 0
      }
    })(this),
    error: (function (_this) {
      return function () {
        let ref2, ref3
        _this.show(_this.model)
        _this.el.querySelector('.conference-loading-indicator').style.display = 'none'
        ReactDOM.unmountComponentAtNode(spinnerDomEl)
        $.flashError(conference_name + I18n.t(' Attendees Failed to Sync.'))
        if ((ref2 = _this.el.querySelector("a[data-testid='settings-cog']")) != null) {
          ref2.classList.remove('ui-state-disabled')
        }
        return (ref3 = _this.el.querySelector("a[data-testid='start-button']")) != null
          ? ref3.removeAttribute('disabled')
          : void 0
      }
    })(this),
  })
  return this.$(form).submit()
}

ConferenceView.prototype.edit = function (_e) {
  // refocus if edit not finalized
  return this.$el.find('.al-trigger').focus()
}

ConferenceView.prototype.toJSON = function () {
  const json = ConferenceView.__super__.toJSON.apply(this, arguments)
  json.auth_token = authenticity_token()
  return json
}

ConferenceView.prototype.delete = function (e) {
  let allCogs, curIndex, currentCog
  e.preventDefault()
  if (
    // eslint-disable-next-line no-alert
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

ConferenceView.prototype.close = function (e) {
  e.preventDefault()
  if (
    // eslint-disable-next-line no-alert
    !window.confirm(
      I18n.t(
        'confirm.close',
        'Are you sure you want to end this conference?\n\nYou will not be able to reopen it.'
      )
    )
  ) {
    return
  }
  return $.ajaxJSON(
    $(e.currentTarget).attr('href'),
    'POST',
    {},
    (function (_this) {
      return function (_data) {
        return window.router.close(_this.model)
      }
    })(this)
  )
}

ConferenceView.prototype.start = function (e) {
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
      clearInterval(i)
      return window.location.reload(true)
    }
  }, 100))
}

ConferenceView.prototype.external = function (e) {
  e.preventDefault()
  const loading_text = I18n.t('loading_urls_message', 'Loading, please wait...')
  const $self = $(e.currentTarget)
  const link_text = $self.text()
  if (link_text === loading_text) {
    return
  }
  $self.text(loading_text)
  return $.ajaxJSON($self.attr('href'), 'GET', {}, function (data) {
    let $a, $box, datum, j, len
    $self.text(link_text)
    if (data.length === 0) {
      return $.flashError(
        I18n.t(
          'no_urls_error',
          "Sorry, it looks like there aren't any %{type} pages for this conference yet.",
          {
            type: $self.attr('name'),
          }
        )
      )
    } else if (data.length > 1) {
      $box = $(document.createElement('DIV'))
      $box.append(
        $('<p />').text(
          I18n.t(
            'multiple_urls_message',
            'There are multiple %{type} pages available for this conference. Please select one:',
            {
              type: $self.attr('name'),
            }
          )
        )
      )
      for (j = 0, len = data.length; j < len; j++) {
        datum = data[j]
        $a = $('<a />', {
          href: datum.url || $self.attr('href') + '&url_id=' + datum.id,
          target: '_blank',
        })
        $a.text(datum.name)
        $box.append($a).append('<br>')
      }
      return $box.dialog({
        width: 425,
        minWidth: 425,
        minHeight: 215,
        resizable: true,
        height: 'auto',
        title: $self.text(),
        modal: true,
        zIndex: 1000,
      })
    } else {
      return window.open(data[0].url)
    }
  })
}

ConferenceView.prototype.deleteRecording = function (e) {
  let $button
  e.preventDefault()
  // eslint-disable-next-line no-alert
  if (window.confirm(I18n.t('Are you sure you want to delete this recording?'))) {
    $button = $(e.currentTarget).parents('div.ig-button')
    return $.ajaxJSON($button.data('url') + '/recording', 'DELETE', {
      recording_id: $button.data('id'),
    })
      .done(
        (function (_this) {
          return function (data, _status) {
            if (data.deleted) {
              return _this.removeRecordingRow($button)
            }
            return $.flashError(
              I18n.t('Sorry, the action performed on this recording failed. Try again later')
            )
          }
        })(this)
      )
      .fail(
        (function (_this) {
          return function (_xhr, _status) {
            return $.flashError(
              I18n.t('Sorry, the action performed on this recording failed. Try again later')
            )
          }
        })(this)
      )
  }
}

ConferenceView.prototype.removeRecordingRow = function ($button) {
  const $row = $('.ig-row[data-id="' + $button.data('id') + '"]')
  const $conferenceId = $($row.parents('div.ig-sublist')).data('id')
  $row.parents('li.recording').remove()
  this.updateConferenceDetails($conferenceId)
  return $.screenReaderFlashMessage(I18n.t('Recording was deleted'))
}

ConferenceView.prototype.updateConferenceDetails = function (id) {
  const $info = $('div.ig-row#conf_' + id).find('div.ig-info')
  const $detailRecordings = $info.find('div.ig-details__item-recordings')
  const $recordings = $('.ig-sublist#conference-' + id)
  const recordings = $recordings.find('li.recording').length
  if (recordings > 1) {
    $detailRecordings.text(
      I18n.t('%{count} Recordings', {
        count: recordings,
      })
    )
    return
  }
  if (recordings === 1) {
    $detailRecordings.text(
      I18n.t('%{count} Recording', {
        count: 1,
      })
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
