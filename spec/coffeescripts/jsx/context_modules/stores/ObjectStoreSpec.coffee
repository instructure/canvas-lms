define ['jsx/context_modules/stores/ObjectStore'], (store) ->
  QUnit.module 'ObjectStore',
    setup: ->
      @testStore = new store('/api/v1/courses/2/folders')
      @server = sinon.fakeServer.create()

      @foldersPageOne = [
        {
            "full_name": "course files/@123",
            "id": 112,
            "name": "@123",
            "parent_folder_id": 13,
            "position": 16,
            "locked": false,
            "folders_url": "http://canvas.dev/api/v1/folders/112/folders",
            "files_url": "http://canvas.dev/api/v1/folders/112/files",
            "files_count": 0,
            "folders_count": 3
        },
        {
            "full_name": "course files/A new special folder",
            "id": 103,
            "name": "A new special folder",
            "parent_folder_id": 13,
            "position": 13,
            "locked": false,
            "folders_url": "http://canvas.dev/api/v1/folders/103/folders",
            "files_url": "http://canvas.dev/api/v1/folders/103/files",
            "files_count": 0,
            "folders_count": 0
        }
      ]
      @foldersPageTwo = [
        {
            "full_name": "course files/@123",
            "id": 325,
            "name": "@123",
            "parent_folder_id": 13,
            "position": 16,
            "locked": false,
            "folders_url": "http://canvas.dev/api/v1/folders/325/folders",
            "files_url": "http://canvas.dev/api/v1/folders/325/files",
            "files_count": 0,
            "folders_count": 0
        },
        {
            "full_name": "course files/A new special folder",
            "id": 326,
            "name": "A new special folder",
            "parent_folder_id": 13,
            "position": 13,
            "locked": false,
            "folders_url": "http://canvas.dev/api/v1/folders/326/folders",
            "files_url": "http://canvas.dev/api/v1/folders/326/files",
            "files_count": 0,
            "folders_count": 0
        }
      ]
      @foldersPageThree = [
        {
            "full_name": "course files/@123",
            "id": 123,
            "name": "@123",
            "parent_folder_id": 13,
            "position": 16,
            "locked": false,
            "folders_url": "http://canvas.dev/api/v1/folders/325/folders",
            "files_url": "http://canvas.dev/api/v1/folders/325/files",
            "files_count": 0,
            "folders_count": 0
        },
        {
            "full_name": "course files/A new special folder",
            "id": 456,
            "name": "A new special folder",
            "parent_folder_id": 13,
            "position": 13,
            "locked": false,
            "folders_url": "http://canvas.dev/api/v1/folders/326/folders",
            "files_url": "http://canvas.dev/api/v1/folders/326/files",
            "files_count": 0,
            "folders_count": 0
        }
      ]

      @testStore.reset()

    teardown: ->
      @server.restore()
      @testStore.reset()

  test 'fetch', ->
    @server.respondWith "GET", /\/folders/, [200, { "Content-Type": "application/json" }, JSON.stringify(@foldersPageOne)]
    @testStore.fetch()
    @server.respond()
    deepEqual @testStore.getState().items, @foldersPageOne, "Should get one page of items"

  test 'fetch with fetchAll', ->
    linkHeaders = '<http://folders?page=1&per_page=2>; rel="current",' +
                  '<http://page2>; rel="next",' +
                  '<http://folders?page=1&per_page=2>; rel="first",' +
                  '<http://page2>; rel="last"'
    linkHeaders2 = '<http://folders?page=2&per_page=2>; rel="current",' +
                  '<http://page3>; rel="next",' +
                  '<http://folders?page=1&per_page=2>; rel="first",' +
                  '<http://page3>; rel="last"'

    @server.respondWith "GET", /\/folders/, [200, { "Content-Type": "application/json", "Link": linkHeaders }, JSON.stringify(@foldersPageOne)]
    @testStore.fetch({fetchAll: true})
    @server.respond()

    @server.respondWith "GET", /page2/, [200, { "Content-Type": "application/json", "Link": linkHeaders2 }, JSON.stringify(@foldersPageTwo)]
    @server.respond()

    @server.respondWith "GET", /page3/, [200, { "Content-Type": "application/json"}, JSON.stringify(@foldersPageThree)]
    @server.respond()
    deepEqual @testStore.getState().items, @foldersPageOne.concat(@foldersPageTwo).concat(@foldersPageThree), "Should get all pages of items"

  test 'fetch with error', ->
    @server.respondWith "GET", /\/folders/, [500, {}, ""]
    @testStore.fetch()
    @server.respond()
    state = @testStore.getState()
    equal state.items.length, 0, "Shouldn't load any items"
    equal state.hasMore, true, "Should set the hasMore flag"
    equal state.isLoaded, false, "Should make the isLoaded flag false"
