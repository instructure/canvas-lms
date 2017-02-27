define [
  'compiled/external_tools/ExternalToolCollection'
], (ExternalToolCollection) ->

  data = [
    {
      "description": "Embed files from Box.net"
      "domain": "localhost"
      "id": "1"
      "name": "Box"
    },
    {
      "description": "This example LTI Tool Provider supports LIS Outcome..."
      "domain": "lti-tool-provider.herokuapp.com"
      "id": "2"
      "name": "Brad's Tool"
    }
  ]

  QUnit.module 'ExternalToolCollection',
    setup: ->
      @externalToolCollection = new ExternalToolCollection
      @externalToolCollection.add(data)

  test 'finds a tool by id', ->
    tool = @externalToolCollection.findWhere({ id: '1'})
    equal tool.get('name'), 'Box'
