define [
  './environment_setup'
], (env) ->
  verifyRoute = (path, expected) ->
    visit(path)
    andThen ->
      wait().then ->
        # this can change to currentRoute() once we update ember >= 1.5.0
        currentRoute = App.__container__.lookup('controller:application').get('currentRouteName')
        equal currentRoute, expected

  testRedirection = (options) ->
    {path, defaultRoute, redirectRoute} = options
    test "permissioned users should see #{defaultRoute}", ->
      env.setUserPermissions(true, true)
      verifyRoute(path, defaultRoute)

    test 'redirect non-permissioned users to #{redirectRoute}', ->
      env.setUserPermissions(false, false)
      verifyRoute(path, redirectRoute)

  testRedirection
