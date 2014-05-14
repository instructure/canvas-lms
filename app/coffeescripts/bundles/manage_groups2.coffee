require [
  'jquery'
  'compiled/views/groups/manage/GroupCategoriesView'
  'compiled/collections/GroupCategoryCollection'
], ($, GroupCategoriesView, GroupCategoryCollection) ->

  groupCategories = new GroupCategoryCollection(ENV.group_categories)

  @app = new GroupCategoriesView
    collection: groupCategories
  @app.render()
  $('#content').html @app.$el

