define ['jquery', 'compiled/views/GoogleDocsTreeView'], ($, GoogleDocsTreeView) ->

  file1 = { name: 'File 1', extension: 'tst', document_id: '12345', alternate_url: {href: '#'}}
  fileData = { files: [file1] }
  folderData = { folders: [ { name: 'Folder 1', files: [file1] } ] }

  module 'GoogleDocsTreeView'

  test 'renders a top level file', ()->
    tree = new GoogleDocsTreeView({model: fileData})
    tree.render()
    equal tree.$el.html().match(/>File 1<\/span>/).length, 1

  test 'gives the file link a title', ()->
    tree = new GoogleDocsTreeView({model: fileData})
    tree.render()
    equal tree.$el.html().match(/title="View in Separate Window"/).length, 1

  test 'renders a folder', ()->
    tree = new GoogleDocsTreeView({model: folderData})
    tree.render()
    equal tree.$el.html().match(/<li class="folder.*\n\s+Folder 1/).length, 1

  test 'gives a nested file link a title', ()->
    tree = new GoogleDocsTreeView({model: folderData})
    tree.render()
    equal tree.$el.html().match(/title="View in Separate Window"/).length, 1

  test 'activateFile triggers an event', ()->
    tree = new GoogleDocsTreeView({model: fileData})
    tree.on 'activate-file', (file_id)->
      equal file_id, file1.document_id
    tree.render()
    tree.$('li.file').click()

  test 'activateFolder delegates through to clicking the sign', ()->
    expect 1
    tree = new GoogleDocsTreeView({model: folderData})
    tree.render()
    tree.$(".sign").on 'click', ()->
      ok 'got clicked'
    tree.$('li.folder').click()


