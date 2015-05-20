define ['jquery', 'underscore', 'Backbone'], ($, _, Backbone) ->

  class FeatureFlag extends Backbone.Model

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
      _.include(['off', 'hidden'], @state()) or (!@currentContextIsAccount() and @isAllowed())

    isHidden: ->
      @flag().hidden

    isLocked: ->
      @flag().locked

    isSiteAdmin: ->
      !!ENV.ACCOUNT?.site_admin

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
        isOff: @isOff(), isOn: @isOn(), isSiteAdmin: @isSiteAdmin() && !@isOn() && !@isLocked(),
        currentContextIsAccount: @isContext('account'),
        threeState: @currentContextIsAccount() && !@transitionLocked('allowed'),
        disableOn: @isLocked() || @isSiteAdmin() || @transitionLocked('on'),
        disableAllow: @isLocked() || @transitionLocked('allowed'),
        disableOff: @isLocked() || @transitionLocked('off'),
        disableToggle: @isLocked() || @transitionLocked('on') || @transitionLocked('off'))

    parse: (json) ->
      _.extend(json, @attributes)
      feature =
        appliesTo: json.applies_to.toLowerCase()
        id: json.feature
        title: json.display_name
        releaseOn: if json.enable_at then new Date(json.enable_at) else null
        releaseNotesUrl: json.release_notes_url
        labels: []
      feature.labels.push(FeatureFlag::LABEL.beta)        if json.beta
      feature.labels.push(FeatureFlag::LABEL.hidden)      if json.feature_flag.hidden
      feature.labels.push(FeatureFlag::LABEL.development) if json.development
      _.extend(json, feature)
