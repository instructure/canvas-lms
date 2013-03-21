define [
  'underscore'
  'Backbone'
  'compiled/models/DaySubstitution'
], (_, Backbone, DaySubstitution) ->

  class DaySubstitutionCollection extends Backbone.Collection
    model: DaySubstitution

    # This rips out the day sub days from their respective models as well as
    # eliminates any duplicated days. For instance, a daySub might have
    # the following attributes: 
    #    "0" : "5"
    #  Another subDay might have
    #    "3" : "4"
    # This will take all of those attributes and put them in one object. The 
    # result will look like this. 
    #   {"0" : "5", "3" : "4"}
    #
    # @api public backbone override 
    toJSON: -> 
     @reduce(
        (memo, daySub) => _.extend(memo, daySub.attributes)
      , {})
