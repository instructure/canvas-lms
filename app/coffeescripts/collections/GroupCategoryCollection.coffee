define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/GroupCategory'
], (PaginatedCollection, GroupCategory) ->

  class GroupCategoryCollection extends PaginatedCollection
    model: GroupCategory
    comparator: (category) ->
      prefix = if category.get('role') is 'uncategorized'
        '2_'
      else if category.get('protected')
        '0_'
      else
        '1_'
      prefix + category.get('name').toLowerCase()

    _defaultUrl: -> "/api/v1/group_categories"
