define [
  'ember'
], (Ember) ->

  FolderController = Ember.ObjectController.extend
    needs: ['files']

    bubbleCurrentFolder: (->
      @get('controllers.files').set('currentFolder', @get('model'))
    ).observes('model')

    actions: {}