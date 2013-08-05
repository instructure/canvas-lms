define [
  'jquery'
  'jst/Modules/ModuleCollectionView'
  'compiled/views/Modules/ModuleView'
  'compiled/views/PaginatedCollectionView'
  'i18n!context_modules'
], ($, template, ModuleView, PaginatedCollectionView, I18n) ->

  class ModulesCollectionView extends PaginatedCollectionView

    template: template
    itemView: ModuleView