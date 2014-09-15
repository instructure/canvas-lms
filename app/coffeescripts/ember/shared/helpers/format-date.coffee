define ['jquery', 'ember', 'timezone', 'underscore'], ($, Ember, tz, _) ->

  {Handlebars} = Ember

  ##
  # Formats a parsable date with normal strftime formats
  #
  # ```html
  # {{format-date datetime '%b %d'}}
  # ```

  Handlebars.registerBoundHelper 'format-date', (datetime, format) ->
    return unless datetime?
    format = '%b %e, %Y %l:%M %P' unless typeof format is 'string'
    tz.format(tz.parse(datetime), format)

