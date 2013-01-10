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
      @role = options.requestParams['enrollment_role']
      @fetchOptions = data: $.extend {}, ENV.USER_PARAMS, options.requestParams
      @collection = new UserCollection()
      @collection.url = options.url
      @collection.on 'add', @renderUser
      @collection.on 'reset', @render
      if options.count > 0
        @$el.disableWhileLoading @collection.fetch(@fetchOptions)
      @paginationScrollContainer = @$el
      et = @el.id.split('_')[0]
      if et == 'role'
        @role_tag = @el.id
      else
        @role_tag = et
      super fetchOptions: @fetchOptions

    render: ->
      @collection.each @renderUser
      super

    incrementCount: (user) =>
      $(c).text(parseInt($(c).text()) + 1) for c in $(".#{@role_tag}_count")

    renderUser: (user) =>
      @$el.append (new UserView model: user, role: @role, role_tag: @role_tag).render().el
