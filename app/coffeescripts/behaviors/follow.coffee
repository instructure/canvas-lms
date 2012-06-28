##
# Listens to clicks on elements that have `data-follow` attributes.
# the attribute should be set to '{"id":5, "type": "user"}' of the item you want to (un)follow.
# When complete,
# publishes a '(un)follow' event with [id, type, ServerResp, 'success', jqXHR] as args

# markup examples:
#   <a data-follow='{"id":5, "type": "user"}' href="#">Follow user 5</a>
#   <a data-follow='{"id":5, "type": "collection"}' href="#">UN-follow collection 5</a>

define [
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'vendor/jquery.ba-tinypubsub'
], ($, _, preventDefault, {publish}) ->

  followableTypes =
    user: '/api/v1/users'
    collection: '/api/v1/collections'

  _.each {follow: 'PUT', unfollow: 'DELETE'}, (method, action) ->
    $(document).delegate "[data-#{action}]", 'click', preventDefault ->
      {type, id} = $(this).data(action)
      url = "#{followableTypes[type]}/#{id}/followers/self"
      $.ajax(url, type: method).success ->
        publish action, [id, type, arguments...]