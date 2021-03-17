#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

import $ from 'jquery'
import _ from 'underscore'
import I18n from 'i18n!observees'
import pairingCodeTemplate from 'jst/PairingCodeUserObservees'
import itemView from './UserObserveeView'
import PaginatedCollectionView from './PaginatedCollectionView'
import 'jquery.disableWhileLoading'

export default class UserObserveesView extends PaginatedCollectionView
  autoFetch: true
  itemView: itemView
  className: 'user-observees'

  template: pairingCodeTemplate

  events:
    'submit .add-observee-form': 'addObservee'
    'click .remove-observee': 'removeObservee'

  els: _.extend {}, PaginatedCollectionView::els,
    '.add-observee-form': '$form'

  initialize: ->
    super
    @collection.on 'beforeFetch', =>
      @setLoading(true)
    @collection.on 'fetch', =>
      @setLoading(false)
    @collection.on 'fetched:last', =>
      @checkEmpty()
    @collection.on 'remove', =>
      @checkEmpty()

  checkEmpty: =>
    $('<em>').text(I18n.t('No students being observed')).appendTo(@$('.observees-list-container')) if @collection.size() == 0

  addObservee: (ev) ->
    ev.preventDefault()
    data = @$form.getFormData()
    d = $.post(@collection.url(), data)

    d.done (model) =>
      if model.redirect
        if confirm I18n.t("In order to complete the process you will be redirected to a login page where you will need to log in with your child's credentials.")
          window.location = model.redirect

      else
        @collection.add([model], merge: true)
        $.flashMessage(I18n.t('observee_added', 'Now observing %{user}', user: model.name))

        @$form.get(0).reset()
        @focusForm()

    d.error (response) =>
      @$form.formErrors(JSON.parse(response.responseText))

      @focusForm()

  removeObservee: (ev) ->
    ev.preventDefault()
    id = $(ev.target).data('user-id')
    user_name = $(ev.target).data('user-name')
    if confirm I18n.t("Are you sure you want to stop observing %{name}?", name: user_name)
      @$form.disableWhileLoading $.ajaxJSON("/api/v1/users/self/observees/#{id}", 'DELETE', {}, () => @removedObservee(id, user_name))

  removedObservee: (id, name) ->
    @collection.remove(id)
    $.flashMessage(I18n.t('No longer observing %{user}', user: name))

  focusForm: ->
    field = @$form.find(":input[value='']:not(button)").first()
    field = @$form.find(":input:not(button)") unless field.length
    field.focus()

  setLoading: (loading) ->
    if loading
      @$('.observees-list-container').attr('aria-busy', 'true')
      @$('.loading-indicator').show()
    else
      @$('.observees-list-container').attr('aria-busy', 'false')
      @$('.loading-indicator').hide()
