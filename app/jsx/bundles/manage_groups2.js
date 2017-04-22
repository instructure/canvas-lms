import $ from 'jquery'
import GroupCategoriesView from 'compiled/views/groups/manage/GroupCategoriesView'
import GroupCategoryCollection from 'compiled/collections/GroupCategoryCollection'

const groupCategories = new GroupCategoryCollection(ENV.group_categories)

const app = new GroupCategoriesView({collection: groupCategories})
app.render()
$('#content').html(app.$el)
