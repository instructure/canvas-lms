define [
  'i18n!assignments'
  'Backbone'
  'jquery'
  'jst/assignments/EditHeaderView'
  'jquery.disableWhileLoading'
], (I18n, Backbone, $, template) ->

  class EditHeaderView extends Backbone.View

    template: template

    events:
      'click .delete_assignment_link': 'onDelete'

    messages:
      confirm: I18n.t('confirms.delete_assignment', 'Are you sure you want to delete this assignment?')

    onDelete: (e) =>
      e.preventDefault()
      @delete() if confirm(@messages.confirm)

    delete: ->
      disablingDfd = new $.Deferred()
      if destroyDfd = @model.destroy()
        destroyDfd.then(@onSaveSuccess)
        destroyDfd.fail -> disablingDfd.reject()
        $('#content').disableWhileLoading disablingDfd
      else
        # .destroy() returns false if model isNew
        @onDeleteSuccess()

    onDeleteSuccess: ->
      location.href = ENV.ASSIGNMENT_INDEX_URL

    toJSON: -> @model.toView()
