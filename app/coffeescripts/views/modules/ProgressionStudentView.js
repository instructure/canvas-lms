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

define [
  'jquery'
  'Backbone'
  '../../collections/ModuleCollection'
  'jst/modules/ProgressionStudentView'
  'jst/modules/ProgressionModuleCollection'
  '../PaginatedCollectionView'
  '../modules/ProgressionModuleView'
], ($, Backbone, ModuleCollection, template, collectionTemplate, PaginatedCollectionView, ProgressionModuleView) ->

  class ProgressionStudentView extends Backbone.View

    tagName: 'li'
    className: 'student'
    template: template

    events:
      'click': 'showProgressions'

    initialize: ->
      super
      @$index = @model.collection.view.$el
      @$students = @$index.find('#progression_students')
      @$modules = @$index.find('#progression_modules')

    afterRender: ->
      super
      @showProgressions() if !@model.collection.currentStudentView
      @syncHeight()

    createProgressions: ->
      studentId = @model.get('id')
      modules = new ModuleCollection null,
        course_id: ENV.COURSE_ID
        per_page: 50
        params:
          student_id: studentId
          include: ['items']
      modules.student_id = studentId
      modules.syncHeight = @syncHeight
      modules.fetch()

      studentUrl = "#{ENV.COURSE_USERS_PATH}/#{studentId}"
      @progressions = new PaginatedCollectionView
        collection: modules
        itemView: ProgressionModuleView
        template: collectionTemplate
        student: @model.attributes
        studentUrl: studentUrl
        autoFetch: true

      @progressions.render()
      @progressions.$el.appendTo(@$modules)

    showProgressions: ->
      @$modules.attr('aria-busy', 'true')
      @model.collection.currentStudentView?.hideProgressions()
      @model.collection.currentStudentView = this

      @syncHeight()
      @$el.addClass('active').attr('aria-selected', true)
      if !@progressions
        @createProgressions()
      else
        @progressions.show()

    hideProgressions: ->
      @progressions.hide()
      @$el.removeClass('active').removeAttr('aria-selected')

    syncHeight: =>
      setTimeout =>
        @$students.height(@$modules.height())
        @$students.find('.collectionViewItems').
          height((@$students.height() || 0) - (@$students.find('.header').height() || 16) - 16)
      , 0

