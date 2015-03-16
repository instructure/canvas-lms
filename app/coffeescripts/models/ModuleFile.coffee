define [
  'jquery'
  'underscore'
  'compiled/models/FilesystemObject'
], ($, _, FilesystemObject) ->
  class ModuleFile extends FilesystemObject
    initialize: (attributes, options) ->
      super
