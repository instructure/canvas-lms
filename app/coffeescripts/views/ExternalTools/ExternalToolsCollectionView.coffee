define [
  'jquery'
  'str/htmlEscape'
  'jst/ExternalTools/ExternalToolsCollectionView'
  'compiled/views/ExternalTools/ExternalToolView'
  'compiled/views/PaginatedCollectionView'
  'i18n!external_tools'
], ($, htmlEscape, template, ExternalToolView, PaginatedCollectionView, I18n) ->

  class ExternalToolsCollectionView extends PaginatedCollectionView

    template: template
    itemView: ExternalToolView
