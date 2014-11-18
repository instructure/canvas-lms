define [
  'jquery'
  'underscore'
  'i18n!react_files'
  'react'
  '../modules/customPropTypes'
  '../modules/filesEnv'
  ], ($, _, I18n, React, customPropTypes, filesEnv) ->

  {select, option, div, input, label} = React.DOM

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

  UsageRightsSelectBox = React.createClass
    displayName: 'UsageRightsSelectBox'

    propTypes:
      use_justification: React.PropTypes.oneOf(_.pluck(contentOptions, 'value'))
      copyright: React.PropTypes.string

    getInitialState: ->
      showTextBox: @props.use_justification
      showCreativeCommonsOptions: @props.use_justification == 'creative_commons' && @props.copyright?
      licenseOptions: false

    componentDidMount: ->
      @getUsageRightsOptions()

    apiUrl: "/api/v1/#{filesEnv.contextType}/#{filesEnv.contextId}/content_licenses"


    # Exposes the selected values to the outside world.
    getValue: ->
      use_justification: @refs.usageRightSelection.getDOMNode().value
      copyright: @refs.copyright.getDOMNode().value if @state.showTextBox
      cc_license: @refs.creativeCommons.getDOMNode().value if @state.showCreativeCommonsOptions


    getUsageRightsOptions: ->
      $.get @apiUrl, (data) =>
        @setState({
          licenseOptions: data
        })

    handleChange: (event) ->
      @setState({
        showTextBox: true
        showCreativeCommonsOptions: event.target.value == 'creative_commons'
      })

    renderContentOptions: ->
      contentOptions.map (contentOption) ->
        option {value: contentOption.value},
          contentOption.display

    renderCreativeCommonsOptions: ->
      onlyCC = @state.licenseOptions.filter (license) ->
        license.id.indexOf('cc') == 0

      onlyCC.map (license) ->
        option {value: license.id},
          license.name




    render: ->
      div {className: 'UsageRightsSelectBox__container'},
        div {className: 'control-group'},
          label {
            className: 'control-label'
            htmlFor: 'usageRightSelector'
          },
            I18n.t('Usage Right:')
          div {className: 'controls'},
            select {
              id: 'usageRightSelector'
              className: 'UsageRightsSelectBox__select',
              onChange: @handleChange,
              ref: 'usageRightSelection'
              defaultValue: @props.use_justification if @props.use_justification
            },
              @renderContentOptions()
        if @state.showCreativeCommonsOptions
          div {className: 'control-group'},
            label {
              className: 'control-label',
              htmlFor: 'creativeCommonsSelection'
            },
              I18n.t('Creative Commons License:')
            div {className: 'controls'},
              select {
                id: 'creativeCommonsSelection',
                className: 'UsageRightsSelectBox__creativeCommons',
                ref: 'creativeCommons',
                defaultValue: @props.copyright
              },
                @renderCreativeCommonsOptions()
        if @state.showTextBox
          div {className: 'control-group'},
            label {
              className: 'control-label',
              htmlFor: 'copyrightHolder'
            },
              I18n.t('Copyright Holder:')
            div {className: 'controls'},
              input {
                id: 'copyrightHolder',
                type: 'text',
                ref: 'copyright',
                defaultValue: @props.copyright if @props.copyright?
                placeholder: I18n.t('(c) 2014 Instructure')
              }