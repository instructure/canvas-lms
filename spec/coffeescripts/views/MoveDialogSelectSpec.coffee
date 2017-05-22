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
  'underscore'
  'jquery'
  'Backbone'
  'compiled/views/MoveDialogSelect'
  'helpers/jquery.simulate'
], (_, $, Backbone, MoveDialogSelect) ->

  class AssignmentStub extends Backbone.Model
    name: -> @get('name')
    toView: =>
      name: @get('name')
      id: @id

  class Assignments extends Backbone.Collection
    model: AssignmentStub

  QUnit.module 'MoveDialogSelect',
    setup: ->
      @set_coll_spy = @spy MoveDialogSelect.prototype, 'setCollection'

      @assignments = new Assignments((id: i, name: "Assignment #{i}") for i in [1..3])
      @view = new MoveDialogSelect
        model: @assignments.at(0)
        excludeModel: true
        lastList: true

  test '#initialize, if a collection is not passed the model\'s collection will be used for @collection', ->
    deepEqual @view.model.collection, @assignments

  test 'if @excludeModel = true, there won\'t be a corresponding <option> for the model', ->
    options = $(@view.render().el).find('option')
    # will be equal because there is an option added for "lastList"
    equal options.length, @assignments.length
    option_with_model_id = _.any options, (ele, ind) =>
      {value} = ele
      value? and value == @assignments.at(0).id
    ok !option_with_model_id

  test '#value get the current value of the select', ->
    $(@view.render().el).find('option').last().prop('selected', true)
    equal @view.value(), 'last'

  test '#getLabelText returns "Place before:" by default', ->
    equal $.trim($(@view.render().el).find('label').text()), "Place before:"

  test '#getLabelText returns the passed value for @labelText', ->
    label = 'hello world'
    view = new MoveDialogSelect
      model: @assignments.at(0)
      labelText: label

    equal $.trim($(view.render().el).find('label').text()), label

  test '#setCollection returns `undefined` if no argument is passed', ->
    @view.setCollection()
    ok @set_coll_spy.returned(undefined)

  test '#setCollection changes the value of @collection', ->
    spy = @spy @view, 'renderOptions'
    other_assignments = new Assignments((id: i, name: "Assignment #{i}") for i in [5..9])
    @view.setCollection(other_assignments)
    deepEqual @view.collection, other_assignments

  test '#toJSON returns an object that can be used for rendering the select', ->
    expected = @view.model.toView()
    expected.items = @view.model.collection.reject((m)=>
      m.id == @view.model.id
    ).map((m)=>
      m.toView()
    )
    expected.labelText = 'Place before:'
    expected.lastList = true

    deepEqual @view.toJSON(), expected
