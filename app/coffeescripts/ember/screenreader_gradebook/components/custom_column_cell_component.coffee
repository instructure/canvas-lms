define [
  'ember'
  'underscore'
], (Ember, _) ->

  CustomColumnCellComponent = Ember.Component.extend

    column: null
    student: null
    dataForStudent: null
    id: (->
      "custom_col_#{@get('column.id')}"
    ).property('column')

    dataForColumn: (->
      studentData = @get('dataForStudent')
      return null unless studentData
      studentData.findBy('column_id', @get('column.id'))
    ).property('student', 'column', 'column.isLoaded', 'dataForStudent.@each.content')

    contentDidChange: (->
       @set('value', @get('dataForColumn.content'))
    ).observes('dataForColumn.content').on('didInsertElement')

    ajax: (url, options) ->
      {type, data} = options
      Ember.$.ajaxJSON url, type, data

    customColURL: ->
      ENV.GRADEBOOK_OPTIONS.custom_column_datum_url

    saveURL: (->
       @customColURL()
         .replace(/:id/, @get('column.id'))
         .replace(/:user_id/, @get('student.id'))
    ).property('column', 'student')

    focusOut: ->
      value = @$('textarea').val()
      return if (value == "" and !@get('dataForColumn')) or value == @get('dataForColumn.content')
      @get('dataForColumn.content')
      xhr = @ajax @get('saveURL'),
        type: "PUT"
        data:"column_data[content]": value

      xhr.then @boundSaveSuccess

    bindSave: (->
      @boundSaveSuccess = _.bind(@onSaveSuccess, this)
    ).on('init')

    onSaveSuccess: (columnDatum) ->
      @sendAction 'on-column-save', columnDatum, @get('column.id')
