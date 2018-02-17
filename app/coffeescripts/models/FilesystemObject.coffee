#
# Copyright (C) 2014 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

define [
  'Backbone'
  'underscore'
  '../str/splitAssetString'
], (Backbone, _, splitAssetString) ->

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
      # Verifies that the parent folder of the item being moved
      # belongs to the same context as the destination.
      # If the destination is different, the item is copied/duplicated
      # instead of moved.
      [contextType, contextId] = if assetString = @get("context_asset_string")
        splitAssetString(assetString, false)
      else
        [@collection.parentFolder?.get("context_type"), @collection.parentFolder?.get("context_id")?.toString()]


      contextType and contextId and
      contextType.toLowerCase() is destination.get("context_type").toLowerCase() and
      contextId is destination.get("context_id")?.toString()

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
      type = if @isFile then "file" else "folder"
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
      objectType = if @isFile then 'files' else 'folders' #TODO find a better way to infer type
      collection = newFolder[objectType]

      if options.dup == 'overwrite' # remove the overwritten object from the collection
        collection.remove(collection.where({display_name: model.get('display_name')}))
      collection.add(model, {merge:true})
      collection
