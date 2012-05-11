define [
  'underscore'
  'str/htmlEscape'
  'compiled/conversations/listWithOthers'
  'jquery.instructure_misc_helpers'
], (_, h, listWithOthers) ->

  format = (context) ->
    str = h(context.name)
    if context.activeFilter
      str = "<span class='active-filter'>#{str}</span>"
    if @options.linkToContexts and context.type is "course"
      str = "<a href='#{h(context.url)}'>#{str}</a>"
    $.raw str

  (contexts, @options) ->
    contexts = _.sortBy(contexts, (context) ->
      "#{if context.activeFilter then 0 else 1}_#{context.name.toLowerCase()}"
    )
    contexts = contexts[0...@options.hardCutoff] if @options.hardCutoff
    contexts = (format(context) for context in contexts)
    listWithOthers(contexts)
