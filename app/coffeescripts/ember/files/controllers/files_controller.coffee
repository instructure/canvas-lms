define [
  'ember'
], (Ember) ->

  FilesController = Ember.Controller.extend

    breadcrumbs: (->
      crumbs = []
      folder = @get('currentFolder')
      while folder
        crumbs.unshift(folder)
        folder = folder.get('parent_folder')
      crumbs
    ).property('currentFolder')