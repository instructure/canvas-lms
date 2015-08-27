define [
  "jsx/assignments/actions/ModerationActions"
], (ModerationActions) ->
  module "ModerationActions",
  test "sets this.store in the constructor", ->
    some_store = {data: true}
    actions = new ModerationActions(some_store)
    ok actions.store.data, "sets the store to true"

  #module "ModerationActions#loadInitalSubmissions",
    #setup: ->
      #@server = sinon.fakeServer.create()
    #teardown: ->
      #@server.restore()

  #test "fetches data from the submissions_url and sets store.addSubmissions with it", ->
    #the_data = {}
    #actions = new ModerationActions(some_store)
    #submission_url = "/something"
    #actions.loadInitialSubmissions(submission_url)
    #expected = {some_thing: 'here'}
    #@server.respond 'get',  submission_url,  [
      #200
      #'Content-Type': 'application/json'
      #JSON.stringify expected
    #]


    #equal the_data, expected, "gets data from the url"
