define ->
  route = ->
    @resource 'files', path: '/', ->
      @resource "folder", path: '*fullPath'

