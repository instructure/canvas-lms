define [
  'jquery'
  'jst/Modules/ModuleItemCollectionView'
  'compiled/views/Modules/ModuleItemView'
  'compiled/views/PaginatedCollectionView'
  'i18n!context_modules'
], ($, template, ModuleItemView, PaginatedCollectionView, I18n) ->

  class ModuleItemCollectionView extends PaginatedCollectionView

    template: template
    itemView: ModuleItemView