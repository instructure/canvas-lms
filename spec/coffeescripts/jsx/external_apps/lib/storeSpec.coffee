define ['jsx/external_apps/lib/store'], (store) ->

  initialState = {
    apps: []
    externalTools: []
    filter: 'all'
    filterText: ''
    isLoadedAppReviews: false
    isLoadedApps: false
    isLoadedExternalTools: false
    isLoadingAppReviews: false
    isLoadingApps: false
    isLoadingExternalTools: false
  }

  data = [
    {
      attributes: {
        id: 1,
        name: 'Box'
        categories: ['Foo']
        description: 'Embed files from Box.net'
        domain: 'localhost'
        is_installed: true
      }
    }
    {
      attributes: {
        id: 2
        name: 'Brad\'s Tool'
        categories: ['Bar']
        description: 'This example LTI Tool Provider supports LIS Outcome...'
        domain: 'lti-tool-provider.herokuapp.com'
        is_installed: false
      }
    }
  ]

  module 'External Apps: Store',
    setup: ->
      store.setState(initialState)

  test 'sets initial state', ->
    deepEqual store.getState(), initialState

  test 'filteredApps without filter', ->
    store.setState({ apps: data })
    apps = store.filteredApps()
    equal apps.length, data.length

  test 'filteredApps with filter', ->
    store.setState({ apps: data, filterText: "Brad" })
    apps = store.filteredApps()
    equal apps.length, 1
    equal apps[0].attributes.name, 'Brad\'s Tool'

  test 'filteredApps filter as installed', ->
    store.setState({ apps: data, filter: 'installed' })
    apps = store.filteredApps()
    equal apps.length, 1
    equal apps[0].attributes.name, 'Box'

  test 'configUrl', ->
    params = {
      configUrl: 'http://localhost'
      consumer_key: { value: 'KEY' }
      shared_secret: { value: 'SECRET' }
      foo: { value: 'bar' }
    }
    url = store.configUrl(params)
    equal url, 'http://localhost?foo=bar'