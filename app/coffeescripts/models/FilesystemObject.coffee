define [
  'Backbone'
  'underscore'
], (Backbone, _) ->

  # this is an abstract base class that both File and Folder inherit from.
  # they share a little bit of functionality
   class FilesystemObject extends Backbone.Model

    # our API uses a different attribute for the 'name' of Files and Folders
    # (`display_name` and `name`, respectively).
    # Use this instead of branching when you want to show the name
    # and you don't know if it's going to be a file or folder.
    displayName: ->
      @get('display_name') or @get('name')

    destinationIsSameContext: (destination) ->
      parentFolder = @collection?.parentFolder

      # Verifies that the parent folder of the item being moved
      # belongs to the same context as the destination.
      # If the destination is different, the item is copied/duplicated
      # instead of moved.
      parentFolder &&
        parentFolder.attributes.context_type is destination.attributes.context_type &&
        parentFolder.attributes.context_id.toString() is destination.attributes.context_id.toString()

    moveTo: (newFolder, options = {}) ->
      if @destinationIsSameContext(newFolder)
        @moveToFolder(newFolder, options)
      else
        @copyToContext(newFolder, options)


    moveToFolder: (newFolder, options = {}) ->
      attrs = @setAttributes({parent_folder_id: newFolder.id}, options)
      $.extend(attrs, parent_folder_id: newFolder.id)

      @save({}, {attrs: attrs}).then =>
        @collection.remove this
        @updateCollection this, newFolder, options

    copyToContext: (newFolder, options = {}) ->
      attrs = @setAttributes($.extend({}, @attributes), options)
      type = if @saveFrd then "file" else "folder"
      attrs["source_#{type}_id"] = attrs.id
      delete attrs.id

      clonedModel = new @constructor(_.omit(attrs, 'id', 'parent_folder_id', 'parent_folder_path'))
      collection = @updateCollection clonedModel, newFolder, options
      clonedModel.url = collection.url
      @set('url', collection.url)
      endpoint = "copy_#{type}"
      url =  "/api/v1/folders/#{newFolder.attributes.id}/#{endpoint}"
      clonedModel.save(attrs, {url})

    setAttributes: (attrs = {}, options= {}) ->
      if options.dup == 'overwrite'
        $.extend(attrs, {on_duplicate: 'overwrite'})
      else if options.dup == 'rename'
        if options.name
          $.extend(attrs, {display_name: options.name, name: options.name, on_duplicate: 'rename'})
        else
          $.extend(attrs, {on_duplicate: 'rename'})

      attrs

    updateCollection: (model, newFolder, options) ->
      # add it to newFolder's children
      objectType = if @saveFrd then 'files' else 'folders' #TODO find a better way to infer type
      collection = newFolder[objectType]

      if options.dup == 'overwrite' # remove the overwritten object from the collection
        collection.remove(collection.where({display_name: model.get('display_name')}))
      collection.add(model, {merge:true})
      collection
