define [
  'i18n!dashboard'
  'compiled/views/Dashboard/SideBarSectionView'
  'compiled/collections/ComingUpCollection'
  'compiled/views/Dashboard/ComingUpItemView'
], (I18n, SideBarSectionView, ComingUpCollection, ComingUpItemView) ->

  class ComingUpView extends SideBarSectionView
    collectionClass: ComingUpCollection
    itemView:        ComingUpItemView
    title:           I18n.t 'coming_up', 'Coming Up'
    listClassName:   'coming-up-list'

