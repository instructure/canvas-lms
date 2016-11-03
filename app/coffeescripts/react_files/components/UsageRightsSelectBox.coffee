define [
  'jquery'
  'underscore'
  'i18n!react_files'
  'react'
  'react-dom'
  '../modules/customPropTypes'
  '../modules/filesEnv'
  '../utils/omitEmptyValues'
  ], ($, _, I18n, React, ReactDOM, customPropTypes, filesEnv, omitEmptyValues) ->

  contentOptions = [{
      display:  I18n.t("Choose usage rights..."),
      value: 'choose'
    },{
      display: I18n.t("I hold the copyright"),
      value: 'own_copyright'
    },{
      display: I18n.t("I have obtained permission to use this file."),
      value: 'used_by_permission'
    },{
      display: I18n.t("The material is in the public domain"),
      value: 'public_domain'
    },{
      display: I18n.t("The material is subject to fair use exception"),
      value: 'fair_use'
    },{
        display: I18n.t("The material is licensed under Creative Commons")
        value: 'creative_commons'
    }]

  UsageRightsSelectBox =
    displayName: 'UsageRightsSelectBox'

    propTypes:
      use_justification: React.PropTypes.oneOf(_.pluck(contentOptions, 'value'))
      copyright: React.PropTypes.string
      showMessage: React.PropTypes.bool
      contextType: React.PropTypes.string
      contextId: React.PropTypes.oneOfType([React.PropTypes.string, React.PropTypes.number])

    getInitialState: ->
      showTextBox: @props.use_justification != 'choose'
      showCreativeCommonsOptions: @props.use_justification == 'creative_commons' && @props.copyright?
      licenseOptions: []
      showMessage: @props.showMessage
      usageRightSelectionValue: @props.use_justification if @props.use_justification

    componentDidMount: ->
      @getUsageRightsOptions()

    apiUrl: ->
      "/api/v1/#{filesEnv.contextType || @props.contextType}/#{filesEnv.contextId || @props.contextId}/content_licenses"


    # Exposes the selected values to the outside world.
    getValues: ->
      obj =
        use_justification: ReactDOM.findDOMNode(@refs.usageRightSelection).value
        copyright: ReactDOM.findDOMNode(@refs.copyright)?.value if @state.showTextBox
        cc_license: ReactDOM.findDOMNode(@refs.creativeCommons)?.value if @state.showCreativeCommonsOptions

      omitEmptyValues obj

    getUsageRightsOptions: ->
      $.get @apiUrl(), (data) =>
        @setState({
          licenseOptions: data
        })

    handleChange: (event) ->
      @setState({
        usageRightSelectionValue: event.target.value
        showTextBox: event.target.value != 'choose'
        showCreativeCommonsOptions: event.target.value == 'creative_commons'
        showMessage: (@props.showMessage && event.target.value == 'choose')
      })

    # This method only really applies to firefox which doesn't handle onChange
    # events on select boxes like every other browser.
    handleChooseKeyPress: (event) ->
      if (event.key == "ArrowUp") || (event.key == "ArrowDown")
        @setState({
          usageRightSelectionValue: event.target.value
        }, @handleChange(event))
