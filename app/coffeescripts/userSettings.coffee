# uses the global ENV.current_user_id and ENV.context_asset_string varibles to store things in
# localStorage (safe, since we only support ie8+) keyed to the user (and current context)
#
# DO NOT PUT SENSITIVE DATA HERE
#
# usage:
#
# userSettings.set 'favoriteColor', 'red'
# userSettings.get 'favoriteColor' # => 'red'
#
# # when you are on /courses/1/x
# userSettings.contextSet 'specialIds', [1,2,3]
# userSettings.contextGet 'specialIds'  # => [1,2,3]
# # when you are on /groups/1/x
# userSettings.contextGet 'specialIds' # => undefined
# # back on /courses/1/x
# userSettings.contextRemove 'specialIds'

define [
  'underscore'

  # used for $.capitalize
  'jquery'
  'jquery.instructure_misc_helpers'
], (_, $) ->
  userSettings = {}

  addTokens = (method, tokens...) ->
    (key, value) ->
      stringifiedValue = JSON.stringify(value)
      joinedTokens = _(tokens).map((token) -> ENV[token]).join('_')
      res = localStorage["#{method}Item"]("_#{joinedTokens}_#{key}", stringifiedValue)
      return undefined if res == "undefined"
      JSON.parse(res) if res

  for method in ['get', 'set', 'remove']
    userSettings[method] = addTokens(method, 'current_user_id')
    userSettings["context#{$.capitalize(method)}"] = addTokens(method, 'current_user_id', 'context_asset_string')

  userSettings
