define [
  'jquery'
  'jst/modules/ModuleItemCollectionView'
  'compiled/views/modules/ModuleItemView'
  'compiled/views/PaginatedCollectionView'
  'i18n!context_modules'
], ($, template, ModuleItemView, PaginatedCollectionView, I18n) ->

  class ModuleItemCollectionView extends PaginatedCollectionView

    template: template
    itemView: ModuleItemView
