define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/GroupCategory'
], (PaginatedCollection, GroupCategory) ->

  class GroupCategoryCollection extends PaginatedCollection
    model: GroupCategory
    comparator: (category) ->
      (if category.get('protected') then '0_' else '1_') +
        category.get('name').toLowerCase()

    _defaultUrl: -> "/api/v1/group_categories"
