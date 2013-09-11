define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/GroupCategory'
], (PaginatedCollection, GroupCategory) ->

  class GroupCategoryCollection extends PaginatedCollection
    model: GroupCategory
    comparator: (category) ->
      (if category.get('role') is 'student_organized' then '1_' else '0_') +
        category.get('name').toLowerCase()

    _defaultUrl: -> "/api/v1/group_categories"
