define [
  'underscore'
  'jsx/shared/CheatDepaginator'
], (_, Depaginate) ->
  listUrl = () =>
    ENV.ENROLLMENT_TERMS_URL

  deserializeTerms = (termGroups) ->
    _.flatten _.map termGroups, (group) ->
      _.map group.enrollment_terms, (term) ->

        groupID = term.grading_period_group_id
        newGroupID = if _.isNumber(groupID) then groupID.toString() else groupID
        {
          id: term.id.toString()
          name: term.name
          startAt: if term.start_at then new Date(term.start_at) else null
          endAt: if term.end_at then new Date(term.end_at) else null
          createdAt: if term.created_at then new Date(term.created_at) else null
          gradingPeriodGroupId: newGroupID
        }

  list: (terms) ->
    promise = new Promise (resolve, reject) =>
      Depaginate(listUrl())
           .then (response) ->
             resolve(deserializeTerms(response))
           .fail (error) ->
             reject(error)
    promise
