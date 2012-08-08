define [
  'use!vendor/backbone'
  'compiled/str/splitAssetString'
  'str/pluralize'
  'compiled/str/underscore'
], (Backbone, splitAssetString, pluralize, underscore) ->

  ##
  # In the spirit of convention over configuration, if the base API route of your collection
  # follows canvas's default routing pattern of:
  #   /api/v1/<context_type>/<context_id>/<plural_name_of_model_class>
  # then you can just fall back on this default 'url' function.  This will look for a @contextCode
  # on your collection and fall back to ENV.context_asset_string. set a @pluralNameOfModelClass
  # property if you need to override what's used as the last part of the url.
  #
  # Feel free to still specicically set a url for your collection if you need to do any disambiguation
  #
  # So, for example say you are on /courses/1 and you do new DiscussionTopicsCollection().fetch()
  # it will go to /api/v1/courses/1/discussion_topics (since ENV.context_asset_string will be already set)
  Backbone.Collection::url = ->
    assetString = @contextAssetString || ENV.context_asset_string
    pluralNameOfModelClass = @pluralNameOfModelClass || pluralize(underscore(@model.name))
    [contextType, contextId] = splitAssetString assetString
    "/api/v1/#{contextType}/#{contextId}/#{pluralNameOfModelClass}"
