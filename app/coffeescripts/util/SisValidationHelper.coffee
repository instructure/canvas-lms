define [], ->

  class SisValidationHelper

    constructor: (params) ->
      @postToSIS = params['postToSIS']
      @dueDateRequired = params['dueDateRequired']
      @dueDate = params['dueDate']
      @modelName = params['name']
      @maxNameLength = params['maxNameLength']

    nameTooLong: ->
      return false unless @postToSIS
      @modelName.length > @maxNameLength

    dueDateMissing: ->
      return false unless @postToSIS
      @dueDateRequired && (@dueDate == null || @dueDate == undefined)
