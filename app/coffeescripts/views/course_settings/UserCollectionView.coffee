define [
  'jquery'
  'underscore'
  'compiled/views/PaginatedView'
  'compiled/views/course_settings/UserView'
  'compiled/collections/UserCollection'
  'compiled/models/User'
], ($, _, PaginatedView, UserView, UserCollection, User) ->

  class UserCollectionView extends PaginatedView

    # options.requestParams are merged with UserCollection#fetch request params
    initialize: (options) ->
      @fetchOptions = data: $.extend {}, ENV.USER_PARAMS, options.requestParams
      @collection = new UserCollection()
      @collection.url = options.url
      @collection.on 'add', @renderUser
      @collection.on 'reset', @render
      @$el.disableWhileLoading @collection.fetch(@fetchOptions)
      @paginationScrollContainer = @$el
      super fetchOptions: @fetchOptions

    render: ->
      @collection.each @renderUser
      super

    renderUser: (user) =>
      @$el.append (new UserView model: user).render().el
