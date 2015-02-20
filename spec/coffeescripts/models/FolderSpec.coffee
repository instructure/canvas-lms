define [
  'compiled/models/Folder'
  'compiled/models/File'
], (Folder, FileModel) ->

  module 'Folder',
    setup: ->
      @file1 = new FileModel({display_name: 'File 1'}, {preflightUrl: '/test'});
      @file2 = new FileModel({display_name: 'file 10'}, {preflightUrl: '/test'});
      @file3 = new FileModel({display_name: 'File 2'}, {preflightUrl: '/test'});
      @file4 = new FileModel({display_name: 'file 20'}, {preflightUrl: '/test'});
      @folder1 = new Folder({name: 'New Folder'})
      @folder2 = new Folder({name: 'Folder'})
      @folder3 = new Folder({name: 'Another Folder'})
      @model = new Folder({contentTypes: 'files'})

      @model.files.push(@file1)
      @model.files.push(@file2)
      @model.files.push(@file3)
      @model.files.push(@file4)
      @model.folders.push(@folder1)
      @model.folders.push(@folder2)
      @model.folders.push(@folder3)
    teardown: ->
      @model = null


  test 'sorts children naturally', ->
    actualChildren = @model.children({})
    expectedChildren = [@folder3, @file1, @file3, @file2, @file4, @folder2, @folder1]
    deepEqual actualChildren, expectedChildren, 'Children did not sort properly'