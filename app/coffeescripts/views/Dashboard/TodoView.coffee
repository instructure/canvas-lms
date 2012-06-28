define [
  'i18n!dashboard'
  'compiled/views/Dashboard/SideBarSectionView'
  'compiled/collections/TodoCollection'
  'compiled/views/Dashboard/TodoItemView'
], (I18n, SideBarSectionView, TodoCollection, TodoItemView) ->

  TodoView = SideBarSectionView.extend
    collectionClass: TodoCollection
    itemView:        TodoItemView
    title:           I18n.t 'todo', 'Todo'
    listClassName:   'to-do-list'

