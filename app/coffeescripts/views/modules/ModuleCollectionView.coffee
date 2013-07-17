define [
  'jquery'
  'jst/modules/ModuleCollectionView'
  'compiled/views/modules/ModuleView'
  'compiled/views/PaginatedCollectionView'
  'i18n!context_modules'
], ($, template, ModuleView, PaginatedCollectionView, I18n) ->

  class ModulesCollectionView extends PaginatedCollectionView
    template: template
    itemView: ModuleView

    @optionProperty 'editable'

    toJSON: ->
      json = super
      json.editable = @editable
      json