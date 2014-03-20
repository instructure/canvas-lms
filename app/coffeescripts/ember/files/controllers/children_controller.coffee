define [
  'ember'
], (Ember) ->

  ChildrenController = Ember.ArrayController.extend

    sortProperties: ['size']

    sortAscending: false

    # sortFunction: function(a,b) {
      # your custom sort logic here
      #return 0 if the two parameters are equal, return a negative value if the first parameter is smaller than the second or return a positive value otherwise

    actions: {}

    sortedColumn: (->
      @get('sortProperties')?.get('firstObject')
    ).property('sortProperties.[]')

    columns: Ember.ArrayProxy.create content: [
      displayName: 'Name'
      property: 'name'
      className: 'ef-name-col'
    ,
      displayName: 'Date Modified'
      property: 'updated_at'
      className: 'ef-date-modified-col'
    ,
      displayName: 'Modified By'
      className: 'ef-modified-by-col'
      property: 'user'
    ,
      displayName: 'Size'
      property: 'size'
      className: 'ef-size-col'
    ]

    toggleSort: (column) ->
      if @get('sortedColumn') is column
        @toggleProperty 'sortAscending'
      else
        @set 'sortProperties', [column]
        @set 'sortAscending', true
      return