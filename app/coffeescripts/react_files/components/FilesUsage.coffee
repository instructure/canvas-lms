define [
  '../modules/customPropTypes'
], (customPropTypes) ->


  FilesUsage =
    displayName: 'FilesUsage'
    url: ->
      "/api/v1/#{@props.contextType}/#{@props.contextId}/files/quota"

    propTypes:
      contextType: customPropTypes.contextType.isRequired
      contextId: customPropTypes.contextId.isRequired

    update: ->
      $.get @url(), (data) =>
        @setState(data)

    componentDidMount: ->
      @update()
      @interval = setInterval @update, 1000*60*5 #refresh every 5 minutes

    componentWillUnmount: ->
      clearInterval @interval

