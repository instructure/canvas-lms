define [
  'jst/ExternalTools/AppCenterView'
  'compiled/views/PaginatedCollectionView'
  'compiled/views/ExternalTools/AppThumbnailView'
], (template, PaginatedCollectionView, AppThumbnailView) ->

  class AppCenterView extends PaginatedCollectionView

    filterText: ''
    targetInstalledState: 'all'

    template: template
    itemView: AppThumbnailView

    renderItem: (model) =>
      filter = new RegExp(@filterText, "i")
      isInstalled = model.get('is_installed') || false
      name = model.get('name') || ''
      categories = model.get('categories') || []

      show = true
      if @targetInstalledState == 'not_installed' && isInstalled
        show = false
      else if @targetInstalledState == 'installed' && !isInstalled
        show = false

      if show && (name.match(filter) || categories.join().match(filter))
        super
