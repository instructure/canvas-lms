#
# Copyright (C) 2013 - present Instructure, Inc.
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
import Backbone from 'Backbone'


export default class FeatureFlag extends Backbone.Model

  LABEL:
    beta        : { cssClass: 'info',      name: 'beta'        }
    hidden      : { cssClass: 'default',   name: 'hidden'      }
    development : { cssClass: 'important', name: 'development' }

  resourceName: 'features'

  urlRoot: ->
    "/api/v1/#{@contextType()}s/#{@contextId()}/features/flags"

  flag: ->
    @get('feature_flag')

  state: ->
    @flag().state

  isAllowed: ->
    @state() == 'allowed'

  isOn: ->
    @state() == 'on'

  isOff: ->
    ['off', 'hidden'].includes(@state()) or (!@currentContextIsAccount() and @isAllowed())

  isHidden: ->
    @flag().hidden

  isLocked: ->
    ENV.PERMISSIONS?.manage_feature_flags == false || @flag().locked

  isSiteAdmin: ->
    !!ENV.ACCOUNT?.site_admin

  # TODO: Remove this and all referencing code once the feature flag is no longer needed
  isResponsive: ->
    !!window.ENV?.FEATURES?.responsive_admin_settings

  isThreeState: ->
    @currentContextIsAccount() && !@transitionLocked('allowed')

  contextType: ->
    ENV.context_asset_string.split('_')[0]

  contextId: ->
    ENV.context_asset_string.split('_')[1]

  isContext: (type) ->
    @contextType() == type.toLowerCase()

  currentContextIsAccount: ->
    ENV.context_asset_string.split('_')[0] == 'account'

  warningFor: (action) ->
    settings = @transitions()[action]
    return if settings?.message then settings else false

  shouldDelete: (action) ->
    @isHidden() && action == 'off'

  updateState: (new_state) =>
    if @shouldDelete(new_state)
      $.ajaxJSON @url(), "DELETE", {}, =>
        # get inherited state
        $.ajaxJSON @url(), "GET", {}, (data) =>
          @updateLocalState(data)
    else
      $.ajaxJSON @url(), "PUT", {state: new_state}, (data) =>
        @updateLocalState(data)

  updateLocalState: (data) ->
    @flag().state = data.state
    @flag().transitions = data.transitions

  transitions: ->
    @get('feature_flag').transitions

  transitionLocked: (action) ->
    settings = @transitions()[action]
    # the button remains enabled if there's an associated message
    return settings?.locked && !settings.message

  toJSON: ->
    _.extend(super, isAllowed: @isAllowed(), isHidden: @isHidden(),
      isOff: @isOff(), isOn: @isOn(), isResponsive: @isResponsive()
      currentContextIsAccount: @isContext('account'),
      threeState: @isThreeState(),
      isResponsiveAndThreeState: @isResponsive() && @isThreeState()
      disableOn: @isLocked() || @transitionLocked('on'),
      disableAllow: @isLocked() || @transitionLocked('allowed'),
      disableOff: @isLocked() || @transitionLocked('off'),
      disableToggle: @isLocked() || @transitionLocked('on') || @transitionLocked('off'))

  parse: (json) ->
    _.extend(json, @attributes)
    feature =
      appliesTo: json.applies_to.toLowerCase()
      id: json.feature
      isExpanded: json.autoexpand
      title: json.display_name
      releaseOn: if json.enable_at then new Date(json.enable_at) else null
      releaseNotesUrl: json.release_notes_url
      labels: []
    feature.labels.push(FeatureFlag::LABEL.beta)        if json.beta
    feature.labels.push(FeatureFlag::LABEL.hidden)      if json.feature_flag.hidden
    feature.labels.push(FeatureFlag::LABEL.development) if json.development
    _.extend(json, feature)
