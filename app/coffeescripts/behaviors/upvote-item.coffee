##
# Listens to clicks on elements that have `data-upvote-item` and `data-deupvote-item` attributes.
# the attribute should be set to the id of the item you want to (de)upvote.
# When complete,
# publishes a '(de)upvoteItem' event with [ServerResp, 'success', jqXHR] as args

# markup examples:
#   <a data-upvote-item='2' href="#">Upvote collectionItem 2</a>
#   <a data-deupvote-item='2' href="#">De-Upvote collectionItem 2</a>

define [
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'vendor/jquery.ba-tinypubsub'
], ($, _, preventDefault, {publish}) ->

  _.each ['upvote', 'deupvote'], (action) ->
    $(document).delegate "[data-#{action}-item]", 'click', preventDefault ->
      itemId = $(this).data("#{action}Item")
      type = {upvote: 'PUT', deupvote: 'DELETE'}[action]
      url = "/api/v1/collections/items/#{itemId}/upvotes/self"
      $.ajax(url, type: type).success ->
        publish "#{action}Item", [itemId, arguments...]