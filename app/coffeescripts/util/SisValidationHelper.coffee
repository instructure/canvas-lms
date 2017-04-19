define [], ->

  class SisValidationHelper

    constructor: (params) ->
      @postToSIS = params['postToSIS']
      @dueDateRequired = params['dueDateRequired']
      @maxNameLengthRequired = params['maxNameLengthRequired']
      @dueDate = params['dueDate']
      @modelName = params['name']
      @maxNameLength = params['maxNameLength']

    nameTooLong: ->
      return false unless @postToSIS
      if @maxNameLengthRequired
        @nameLengthComparison()
      else if !@maxNameLengthRequired && @maxNameLength == 256
        @nameLengthComparison()

    nameLengthComparison: ->
      @modelName.length > @maxNameLength

    dueDateMissing: ->
      return false unless @postToSIS
      @dueDateRequired && (@dueDate == null || @dueDate == undefined)
