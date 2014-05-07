define [
  './jsonapi_adapter'
  '../shared/environment'
], (JSONAPIAdapter, env) ->

  JSONAPIAdapter.extend

    # namespaced behind quizzes
    buildURL: (type, id) ->
      host      = @get('host')
      namespace = @get('namespace')

      url = []
      url.push host if host
      url.push namespace if namespace
      url.push 'quizzes'
      url.push env.get("quizId")
      url.push 'submissions'
      url.push id if id
      url = url.join('/')
      url = "/#{url}" unless host
      url
