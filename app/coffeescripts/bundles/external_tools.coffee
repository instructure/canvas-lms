require [
  'compiled/collections/ExternalToolCollection',
  'compiled/collections/PaginatedCollection',
  'compiled/views/ExternalTools/IndexView'
  'compiled/views/ExternalTools/AppCenterView'
  'compiled/views/ExternalTools/ExternalToolsCollectionView'
  ], (ExternalToolCollection, PaginatedCollection, IndexView, AppCenterView, ExternalToolsCollectionView) ->

    # Collections
    externalTools = new ExternalToolCollection
    externalTools.setParam('per_page', 20)

    apps = new PaginatedCollection
    apps.resourceName = 'app_center/apps'

    # Views
    appCenterView = new AppCenterView
      collection: apps

    externalToolsCollectionView = new ExternalToolsCollectionView
      collection: externalTools

    @app = new IndexView
      externalToolsView: externalToolsCollectionView
      appCenterView: appCenterView
      el: '#external_tools'
      appCenterEnabled: ENV.APP_CENTER.enabled

    @app.render()
    externalTools.fetch()
