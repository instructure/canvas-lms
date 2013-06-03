define [
  'jquery'
  'str/htmlEscape'
  'jst/ExternalTools/ExternalToolsCollectionView'
  'compiled/views/ExternalTools/ExternalToolView'
  'compiled/views/CollectionView'
  'i18n!external_tools'
], ($, htmlEscape, template, ExternalToolView, CollectionView, I18n) ->

  class ExternalToolsCollectionView extends CollectionView

    template: template
    itemView: ExternalToolView
