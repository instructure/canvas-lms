#
# StrongMind Added
#

define [
  'Backbone'
], ({Model}) ->

  class UnassignStudentList
    constructor: (@excludes) ->
      @students = ENV['ALL_STUDENTS']
      @excludes = ENV['UNASSIGNED_STUDENTS']

    resetExcludes: (@new) ->
      @excludes = @new

    getExcludes: () ->
      @excludes
