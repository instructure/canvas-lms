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
import {clone} from 'lodash'
import Backbone from '@canvas/backbone'
import CollectionView from '@canvas/backbone-collection-view'
import ConferenceCollection from './backbone/collections/ConferenceCollection'
import Conference from './backbone/models/Conference'
import ConferenceView from './backbone/views/ConferenceView'
import ConcludedConferenceView from './backbone/views/ConcludedConferenceView'
import EditConferenceView from './backbone/views/EditConferenceView'
import '@canvas/jquery/jquery.ajaxJSON'
import '@canvas/jquery/jquery.instructure_forms'
import 'jqueryui/dialog'
import '@canvas/jquery/jquery.instructure_misc_helpers'
import '@canvas/datetime/jquery'
import '@canvas/jquery-keycodes'
import '@canvas/loading-image'
import '@canvas/rails-flash-notifications'
import '@canvas/util/templateData'
import renderConferenceAlternatives from './react/renderAlternatives'
import ready from '@instructure/ready'
import React from 'react'
import ReactDOM from 'react-dom'
import {VideoConferenceModal} from './react/components/VideoConferenceModal/VideoConferenceModal'
import getCookie from '@instructure/get-cookie'

const I18n = useI18nScope('conferences')

if (ENV.can_create_conferences) {
  if (ENV.render_alternatives) {
    const node = document.getElementById('conference-alternatives-container')
    if (!node) {
      throw new Error('Could not find #conference-alternatives-container')
    }
    renderConferenceAlternatives(node)
  }
}

const ConferencesRouter = Backbone.Router.extend({
  routes: {
    '': 'index',
    'conference_:id': 'edit',
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
      listClassName: 'ig-list',
    }))
    view.render()

    this.concludedConferences = new ConferenceCollection(ENV.concluded_conferences)
    view = this.concludedView = new CollectionView({
      el: $('#concluded-conference-list'),
      itemView: ConcludedConferenceView,
      collection: this.concludedConferences,
      emptyMessage: I18n.t('no_concluded_conferences', 'There are no concluded conferences'),
      listClassName: 'ig-list',
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
    const conference = new Conference(clone(ENV.default_conference))
    conference.once('startSync', () => this.currentConferences.unshift(conference))
    if (conference.get('permissions').create) {
      if (ENV.bbb_modal_update) {
        const {attributes} = conference

        const availableAttendeesList = ENV.users.map(({id, name}) => {
          return {
            displayName: name,
            id,
            type: 'user',
            assetCode: `user-${id}`,
          }
        })

        const availableSectionsList =
          ENV.sections?.map(({id, name}) => {
            return {
              displayName: name,
              id,
              type: 'section',
              assetCode: `section-${id}`,
            }
          }) || []

        const availableGroupsList =
          ENV.groups?.map(({id, name}) => {
            return {
              displayName: name,
              id,
              type: 'group',
              assetCode: `group-${id}`,
            }
          }) || []

        const menuData = availableAttendeesList.concat(availableSectionsList, availableGroupsList)
        ReactDOM.render(
          <VideoConferenceModal
            open={true}
            isEditing={false}
            availableAttendeesList={menuData}
            onDismiss={() => {
              window.location.hash = ''
              ReactDOM.render(<span />, document.getElementById('react-conference-modal-container'))
            }}
            onSubmit={async (e, data) => {
              const context =
                attributes.context_type === 'Course'
                  ? 'courses'
                  : attributes.context_type === 'Group'
                  ? 'groups'
                  : null
              const contextId = attributes.context_id
              const inviteAll = data.invitationOptions.includes('invite_all') ? 1 : 0
              const noTimeLimit = data.options.includes('no_time_limit') ? 1 : 0
              const enableWaitingRoom = data.options.includes('enable_waiting_room') ? 1 : 0
              const duration = noTimeLimit ? '' : data.duration
              const record = data.options.includes('recording_enabled') ? 1 : 0
              const calendar_event = data.options.includes('add_to_calendar') ? 1 : 0
              const start_at = calendar_event ? data.startCalendarDate : null
              const end_at = calendar_event ? data.endCalendarDate : null

              const remove_observers = data.invitationOptions.includes('remove_observers') ? 1 : 0

              const payload = {
                _method: 'POST',
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
                'observers[remove]': remove_observers,
                'web_conference[start_at]': start_at,
                'web_conference[end_at]': end_at,
                'web_conference[calendar_event]': calendar_event,
              }
              if (inviteAll) {
                ENV.users.forEach(userId => {
                  payload[`user[${userId}]`] = 1
                })
              } else {
                data.selectedAttendees.forEach(menuItem => {
                  if (menuItem.type === 'group') {
                    payload[`group[${menuItem.id}]`] = 1
                  } else if (menuItem.type === 'section') {
                    payload[`section[${menuItem.id}]`] = 1
                  } else {
                    payload[`user[${menuItem.id}]`] = 1
                  }
                })
              }

              ;[
                'share_webcam',
                'share_microphone',
                'share_other_webcams',
                'send_public_chat',
                'send_private_chat',
              ].forEach(option => {
                payload[`web_conference[user_settings][${option}]`] =
                  data.attendeesOptions.includes(option) ? 1 : 0
              })

              const requestOptions = {
                credentials: 'same-origin',
                method: 'POST',
                body: new URLSearchParams(payload),
                headers: {
                  'X-CSRF-Token': getCookie('_csrf_token'),
                  Accept: 'application/json',
                },
              }

              if (!context) {
                return false
              }

              const response = await fetch(`/${context}/${contextId}/conferences`, requestOptions)

              if (response.status === 200) {
                $.flashMessage(I18n.t('Conference Saved'))
                window.location.href = window.location.href.split('#')[0]
                return true
              } else {
                $.flashError(I18n.t('There was an error upon saving your conference'))
                return false
              }
            }}
          />,
          document.getElementById('react-conference-modal-container')
        )
      } else {
        this.editView.show(conference)
      }
    }
  },

  edit(conference) {
    conference =
      this.currentConferences.get(conference) || this.concludedConferences.get(conference)
    if (!conference) return
    if (!conference.get('permissions').update) {
      // reached when a user without edit permissions navigates
      // to a specific conference's url directly
      $(`#conf_${conference.get('id')}`)[0].scrollIntoView()
      return
    }
    if (ENV.bbb_modal_update) {
      const {attributes} = conference
      const options = []
      const invitationOptions = []
      const attendeesOptions = []
      const availableAttendeesList = ENV.users.map(({id, name}) => {
        return {
          displayName: name,
          id,
          type: 'user',
          assetCode: `user-${id}`,
        }
      })

      const availableSectionsList =
        ENV.sections?.map(({id, name}) => {
          return {
            displayName: name,
            id,
            type: 'section',
            assetCode: `section-${id}`,
          }
        }) || []

      const availableGroupsList =
        ENV.groups?.map(({id, name}) => {
          return {
            displayName: name,
            id,
            type: 'group',
            assetCode: `group-${id}`,
          }
        }) || []

      const menuData = availableAttendeesList.concat(availableSectionsList, availableGroupsList)
      if (attributes.long_running === 1) {
        options.push('no_time_limit')
      }

      if (attributes.user_settings.record) {
        options.push('recording_enabled')
      }

      if (attributes.user_settings.enable_waiting_room) {
        options.push('enable_waiting_room')
      }

      if (attributes.has_calendar_event && attributes.start_at && attributes.end_at) {
        options.push('add_to_calendar')
      }

      ;[
        'share_webcam',
        'share_other_webcams',
        'share_microphone',
        'send_public_chat',
        'send_private_chat',
      ].forEach(option => {
        if (attributes.user_settings[option]) {
          attendeesOptions.push(option)
        }
      })

      ReactDOM.render(
        <VideoConferenceModal
          open={true}
          isEditing={true}
          hasBegun={!!attributes.started_at}
          type={attributes.conference_type}
          name={attributes.title}
          duration={!attributes.duration ? 0 : attributes.duration}
          options={options}
          description={attributes.description}
          invitationOptions={invitationOptions}
          attendeesOptions={attendeesOptions}
          availableAttendeesList={menuData}
          selectedAttendees={attributes.user_ids.map(u => {
            return {assetCode: `user-${u}`, id: u}
          })}
          startCalendarDate={attributes.start_at}
          endCalendarDate={attributes.end_at}
          onDismiss={() => {
            window.location.hash = ''
            ReactDOM.render(<span />, document.getElementById('react-conference-modal-container'))
          }}
          onSubmit={async (e, data) => {
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
            const calendar_event = data.options.includes('add_to_calendar') ? 1 : 0
            const start_at = calendar_event ? data.startCalendarDate : null
            const end_at = calendar_event ? data.endCalendarDate : null
            const remove_observers = data.invitationOptions.includes('remove_observers') ? 1 : 0

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
              'observers[remove]': remove_observers,
              'web_conference[start_at]': start_at,
              'web_conference[end_at]': end_at,
              'web_conference[calendar_event]': calendar_event,
            }

            if (inviteAll) {
              ENV.users.forEach(userId => {
                payload[`user[${userId}]`] = 1
              })
            } else {
              data.selectedAttendees.forEach(menuItem => {
                if (menuItem.type === 'group') {
                  payload[`group[${menuItem.id}]`] = 1
                } else if (menuItem.type === 'section') {
                  payload[`section[${menuItem.id}]`] = 1
                } else {
                  payload[`user[${menuItem.id}]`] = 1
                }
              })
            }

            ;[
              'share_webcam',
              'share_other_webcams',
              'share_microphone',
              'send_public_chat',
              'send_private_chat',
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
                'X-CSRF-Token': getCookie('_csrf_token'),
                Accept: 'application/json',
              },
            }

            if (!context) {
              return false
            }

            const response = await fetch(
              `/${context}/${contextId}/conferences/${conferenceId}`,
              requestOptions
            )

            if (response.status === 200) {
              $.flashMessage(I18n.t('Conference Saved'))
              window.location.href = window.location.href.split('#')[0]
              return true
            } else {
              $.flashError(I18n.t('There was an error upon saving your conference'))
              return false
            }
          }}
        />,
        document.getElementById('react-conference-modal-container')
      )
    } else {
      this.editConferenceId = conference.get('id')
      this.editView.show(conference, {isEditing: true})
    }
  },

  close(conference) {
    this.currentConferences.remove(conference)
    this.concludedConferences.unshift(conference)
  },
})

ready(() => {
  window.router = new ConferencesRouter()
  Backbone.history.start()
})
