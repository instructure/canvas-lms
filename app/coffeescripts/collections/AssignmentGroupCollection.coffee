define [
  'Backbone'
  'compiled/models/AssignmentGroup'
], (Backbone, AssignmentGroup) ->

  class AssignmentGroupCollection extends Backbone.Collection

    model: AssignmentGroup

    @optionProperty 'course'

    # TODO: this will also return the assignments discussion_topic if it is of
    # that type, which we don't need.
    defaults:
      params:
        include: ["assignments"]
