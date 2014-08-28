define ['jquery', 'underscore', 'Backbone'], ($, _, Backbone) ->

  class FeatureFlag extends Backbone.Model

    LABEL:
      beta        : { cssClass: 'info',      name: 'beta'        }
      hidden      : { cssClass: 'default',   name: 'hidden'      }
      development : { cssClass: 'important', name: 'development' }

    resourceName: 'features'

    urlRoot: ->
      "/api/v1/#{@contextType()}s/#{@contextId()}/features/flags"

    flagContext: ->
      flag = @get('flag')
      "#{flag.context_type}_#{flag.context_id}".toLowerCase()

    hasContext: ->
      flag = @get('flag')
      flag.context_type and flag.context_id

    isAllowed: ->
      @get('state') == 'allowed'

    isOn: ->
      @get('state') == 'on'

    isOff: (forDisplay = false) ->
      cond1 = _.include(['off', 'hidden'], @get('state'))
      cond2 = !@currentContextIsAccount() and @isAllowed()
      if forDisplay then cond1 or cond2 else cond1

    isHidden: ->
      @get('hidden')

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

    updateTransitions: =>
      $.getJSON(@url()).then ({transitions}) =>
        @get('feature_flag').transitions = transitions

    transitions: ->
      @get('feature_flag').transitions

    transitionLocked: (action) ->
      settings = @transitions()[action]
      # the button remains enabled if there's an associated message
      return settings?.locked && !settings.message

    toJSON: ->
      _.extend(super, isAllowed: @isAllowed(), isHidden: @isHidden(),
        isOff: @isOff(true), isOn: @isOn(), isSiteAdmin: @isSiteAdmin(),
        currentContextIsAccount: @isContext('account'),
        disableOn: @transitionLocked('on'), disableAllow: @transitionLocked('allowed'),
        disableOff: @transitionLocked('off'))

    parse: (json) ->
      _.extend(json, @attributes)
      feature =
        appliesTo: json.applies_to.toLowerCase()
        id: json.feature
        title: json.display_name
        isLocked: json.feature_flag.locked
        flag: json.feature_flag
        releaseOn: if json.enable_at then new Date(json.enable_at) else null
        releaseNotesUrl: json.release_notes_url
        state: json.feature_flag?.state
        labels: []
      feature.flag = json.feature_flag if json.feature_flag
      feature.state = json.feature_flag.state if json.feature_flag
      feature.labels.push(FeatureFlag::LABEL.beta)        if json.beta
      feature.labels.push(FeatureFlag::LABEL.hidden)      if json.hidden
      feature.labels.push(FeatureFlag::LABEL.development) if json.development
      _.extend(json, feature)
