define [
  'compiled/collections/PaginatedCollection'
  'compiled/models/GroupCategory'
], (PaginatedCollection, GroupCategory) ->

  class GroupCategoryCollection extends PaginatedCollection
    model: GroupCategory
    comparator: (category) -> category.get('name')

    _defaultUrl: -> "/api/v1/group_categories"
