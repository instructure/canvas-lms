define [
  'Backbone'
], (Backbone) ->

  # this is an abstract base class that both File and Folder inherit from.
  # they share a little bit of functionality
   class FilesystemObject extends Backbone.Model

    # our API uses a different attribute for the 'name' of Files and Folders
    # (`display_name` and `name`, respectively).
    # Use this instead of branching when you want to show the name
    # and you don't know if it's going to be a file or folder.
    displayName: ->
      @get('display_name') or @get('name')

    moveTo: (newFolder, options = {}) ->
      attrs = {parent_folder_id: newFolder.id}
      if options.dup == 'overwrite'
        $.extend(attrs, {on_duplicate: 'overwrite'})
      else if options.dup == 'rename'
        if options.name
          $.extend(attrs, {name: options.name})
        else
          $.extend(attrs, {on_duplicate: 'rename'})
      @save({}, {attrs: attrs}).then =>
        @collection.remove(this)

        # add it to newFolder's children
        myType = if @saveFrd then 'file' else 'folder' #TODO find a better way to infer type
        collection = newFolder[myType+'s']
        if options.dup == 'overwrite' # remove the overwriten object from the collection
          collection.remove(collection.where({display_name: this.get('display_name')}))
        collection.add(this, {merge:true})
