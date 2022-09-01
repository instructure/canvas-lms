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
import _ from 'underscore'
import Backbone from '@canvas/backbone'
import CollectionView from '@canvas/backbone-collection-view'
import ConferenceCollection from './backbone/collections/ConferenceCollection'
import Conference from './backbone/models/Conference'
import ConferenceView from './backbone/views/ConferenceView.coffee'
import ConcludedConferenceView from './backbone/views/ConcludedConferenceView.coffee'
import EditConferenceView from './backbone/views/EditConferenceView.coffee'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/forms/jquery/jquery.instructure_forms'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/keycodes'
import '@canvas/loading-image'
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData'
import '@canvas/datetime'
import renderConferenceAlternatives from './react/renderAlternatives'
import ready from '@instructure/ready'
import React from 'react'
import ReactDOM from 'react-dom'
import {VideoConferenceModal} from './react/components/VideoConferenceModal/VideoConferenceModal'
import getCookie from '@instructure/get-cookie'

const I18n = useI18nScope('conferences')

if (ENV.can_create_conferences) {
  if (ENV.render_alternatives) {
    renderConferenceAlternatives()
  }
}

const ConferencesRouter = Backbone.Router.extend({
  routes: {
    '': 'index',
    'conference_:id': 'edit'
  },

  editView: null,
  currentConferences: null,
  concludedConferences: null,

  initialize() {
    this.close = this.close.bind(this)
    // populate the conference list with inital set of data
    this.editView = new EditConferenceView()

    this.currentConferences = new ConferenceCollection(ENV.current_conferences)
    this.currentConferences.on('change', () => {
      // focus if edit finalized (element is redrawn so we find by id)
      if (this.editConferenceId) {
        $(`#new-conference-list div[data-id=${this.editConferenceId}] .al-trigger`).focus()
      }
    })
    let view = (this.currentView = new CollectionView({
      el: $('#new-conference-list'),
      itemView: ConferenceView,
      collection: this.currentConferences,
      emptyMessage: I18n.t('no_new_conferences', 'There are no new conferences'),
      listClassName: 'ig-list'
    }))
    view.render()

    this.concludedConferences = new ConferenceCollection(ENV.concluded_conferences)
    view = this.concludedView = new CollectionView({
      el: $('#concluded-conference-list'),
      itemView: ConcludedConferenceView,
      collection: this.concludedConferences,
      emptyMessage: I18n.t('no_concluded_conferences', 'There are no concluded conferences'),
      listClassName: 'ig-list'
    })
    view.render()

    $.screenReaderFlashMessage(
      I18n.t(
        'notifications.inaccessible',
        'Warning: This page contains third-party content which is not accessible to screen readers.'
      ),
      20000
    )

    $('.new-conference-btn').on('click', () => this.create())
  },

  index() {
    this.editView.close()
  },

  create() {
    const conference = new Conference(_.clone(ENV.default_conference))
    conference.once('startSync', () => this.currentConferences.unshift(conference))
    if (conference.get('permissions').create) {
      this.editView.show(conference)
    }
  },

  edit(conference) {
    conference =
      this.currentConferences.get(conference) || this.concludedConferences.get(conference)
    if (!conference) return

    if (ENV.bbb_modal_update) {
      const {attributes} = conference
      const options = []
      const invitationOptions = []
      const attendeesOptions = []
      const availableAttendeesList = ENV.users.map(({id, name}) => {
        return {
          displayName: name,
          id
        }
      })

      if (attributes.long_running === 1) {
        options.push('no_time_limit')
      }

      if (attributes.user_settings.record) {
        options.push('recording_enabled')
      }

      if (attributes.user_settings.enable_waiting_room) {
        options.push('enable_waiting_room')
      }

      // TBD Add to Calendar

      ;[
        'share_webcam',
        'share_other_webcams',
        'share_microphone',
        'send_public_chat',
        'send_private_chat'
      ].forEach(option => {
        if (attributes.user_settings[option]) {
          attendeesOptions.push(option)
        }
      })

      ReactDOM.render(
        <VideoConferenceModal
          open={true}
          isEditing={true}
          type={attributes.conference_type}
          name={attributes.title}
          duration={!attributes.duration ? 0 : attributes.duration}
          options={options}
          description={attributes.description}
          invitationOptions={invitationOptions}
          attendeesOptions={attendeesOptions}
          availableAttendeesList={availableAttendeesList}
          selectedAttendees={attributes.user_ids}
          onDismiss={() => {
            window.location.hash = ''
            ReactDOM.render(<span />, document.getElementById('react-conference-modal-container'))
          }}
          onSubmit={(e, data) => {
            const context =
              attributes.context_type === 'Course'
                ? 'courses'
                : attributes.context_type === 'Group'
                ? 'groups'
                : null
            const contextId = attributes.context_id
            const conferenceId = conference.id
            const inviteAll = data.invitationOptions.includes('invite_all') ? 1 : 0
            const noTimeLimit = data.options.includes('no_time_limit') ? 1 : 0
            const duration = noTimeLimit ? '' : data.duration
            const record = data.options.includes('recording_enabled') ? 1 : 0
            const enableWaitingRoom = data.options.includes('enable_waiting_room') ? 1 : 0
            const payload = {
              _method: 'PUT',
              title: data.name,
              'web_conference[title]': data.name,
              conference_type: data.conferenceType,
              'web_conference[conference_type]': data.conferenceType,
              duration,
              'web_conference[duration]': duration,
              'user_settings[record]': record,
              'web_conference[user_settings][record]': record,
              'web_conference[user_settings][enable_waiting_room]': enableWaitingRoom,
              long_running: noTimeLimit,
              'web_conference[long_running]': noTimeLimit,
              description: data.description,
              'web_conference[description]': data.description,
              'user[all]': inviteAll,
              'observers[remove]': 0
            }

            if (inviteAll) {
              ENV.users.forEach(userId => {
                payload[`user[${userId}]`] = 1
              })
            } else {
              data.selectedAttendees.forEach(userId => {
                payload[`user[${userId}]`] = 1
              })
            }

            ;[
              'share_webcam',
              'share_other_webcams',
              'share_microphone',
              'send_public_chat',
              'send_private_chat'
            ].forEach(option => {
              payload[`web_conference[user_settings][${option}]`] = data.attendeesOptions.includes(
                option
              )
                ? 1
                : 0
            })

            const requestOptions = {
              credentials: 'same-origin',
              method: 'POST',
              body: new URLSearchParams(payload),
              headers: {
                'X-CSRF-Token': getCookie('_csrf_token')
              }
            }

            if (!context) {
              return
            }

            fetch(`/${context}/${contextId}/conferences/${conferenceId}`, requestOptions)
              .then(() => {
                // Remove the `conference_N` since it will cause the modal to reopen on the reload.
                window.location.href = window.location.href.split('#')[0]
              })
              .catch(err => {
                throw err
              })
          }}
        />,
        document.getElementById('react-conference-modal-container')
      )
    } else {
      if (conference.get('permissions').update) {
        this.editConferenceId = conference.get('id')
        this.editView.show(conference, {isEditing: true})
      }
      // reached when a user without edit permissions navigates
      // to a specific conference's url directly
      $(`#conf_${conference.get('id')}`)[0].scrollIntoView()
    }
  },

  close(conference) {
    this.currentConferences.remove(conference)
    this.concludedConferences.unshift(conference)
  }
})

ready(() => {
  window.router = new ConferencesRouter()
  Backbone.history.start()
})
