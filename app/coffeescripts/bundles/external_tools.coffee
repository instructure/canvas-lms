require [
  'jst/ExternalTools/AppCenterView'
  'compiled/collections/ExternalToolCollection',
  'compiled/collections/PaginatedCollection',
  'compiled/views/PaginatedCollectionView'
  'compiled/views/ExternalTools/IndexView'
  'compiled/views/ExternalTools/ExternalToolsCollectionView'
  'compiled/views/ExternalTools/AppThumbnailView'
  ], (AppCenterTemplate, ExternalToolCollection, PaginatedCollection, PaginatedCollectionView, 
    IndexView, ExternalToolsCollectionView, AppThumbnailView) ->

    # Collections
    externalTools = new ExternalToolCollection

    apps = new PaginatedCollection
    apps.resourceName = 'app_center/apps'

    # Views
    appCenterView = new PaginatedCollectionView
      template: AppCenterTemplate
      itemView: AppThumbnailView
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
