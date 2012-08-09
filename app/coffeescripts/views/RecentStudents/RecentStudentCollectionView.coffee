define [
  'jquery'
  'underscore'
  'compiled/views/PaginatedView'
  'compiled/views/RecentStudents/RecentStudentView'
], ($, _, PaginatedView, RecentStudentView) ->

  class RecentStudentCollectionView extends PaginatedView

    initialize: (options) ->
      @collection.on 'add', @renderUser
      @collection.on 'reset', @render
      @paginationScrollContainer = @$el
      super

    render: =>
      ret = super
      @collection.each (user) => @renderUser user
      ret

    renderUser: (user) =>
      @$el.append (new RecentStudentView model: user).render().el
