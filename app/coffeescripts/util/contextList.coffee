define [
  'underscore'
  'str/htmlEscape'
  'compiled/util/listWithOthers'
  'jquery.instructure_misc_helpers'
], (_, h, listWithOthers) ->

  prepare = (context, filters) ->
    context = _.clone(context)
    context.activeFilter = _.include(filters, "#{context.type}_#{context.id}")
    context.sortBy = "#{if context.activeFilter then 0 else 1}_#{context.name.toLowerCase()}"
    context

  format = (context, linkToContexts) ->
    str = h(context.name)
    if context.activeFilter
      str = "<span class='active-filter'>#{str}</span>"
    if linkToContexts and context.type is "course"
      str = "<a href='#{h(context.url)}'>#{str}</a>"
    $.raw str

  # given a map of ids by type (e.g. {courses: [1, 2], groups: ...})
  # and a map of possible contexts by type,
  # return an html sentence/list of the contexts (maybe links, etc., see
  # options)
  contextList = (contextMap, allContexts, options = {}) ->
    filters = options.filters ? []
    contexts = []
    for type, ids of contextMap
      contexts = contexts.concat(_.values(_.pick(allContexts[type], ids)))
    contexts = _.chain(contexts)
      .map((context) -> prepare(context, filters))
      .sortBy('sortBy')
      .map((context) -> format(context, options.linkToContexts))
      .value()
    contexts = contexts[0...options.hardCutoff] if options.hardCutoff
    listWithOthers(contexts)
