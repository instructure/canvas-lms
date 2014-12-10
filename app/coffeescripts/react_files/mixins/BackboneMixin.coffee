# this is just https://github.com/usepropeller/react.backbone but without the UMD wrapper.

define [
  'Backbone'
  'underscore'
], (Backbone, _) ->

  collectionBehavior =
    changeOptions: 'add remove reset sort'
    updateScheduler: (func) ->
      _.debounce(func, 0)

  modelBehavior =
    changeOptions: 'change'

    #note: if we debounce models too we can no longer use model attributes
    #as properties to react controlled components due to https://github.com/facebook/react/issues/955
    updateScheduler: _.identity

  subscribe = (component, modelOrCollection, customChangeOptions) ->
    return  unless modelOrCollection
    behavior = (if modelOrCollection instanceof Backbone.Collection then collectionBehavior else modelBehavior)
    triggerUpdate = behavior.updateScheduler ->
      if component.isMounted()
        (component.onModelChange or component.forceUpdate).call(component)
    changeOptions = customChangeOptions or component.changeOptions or behavior.changeOptions
    modelOrCollection.on changeOptions, triggerUpdate, component

  unsubscribe = (component, modelOrCollection) ->
    return  unless modelOrCollection
    modelOrCollection.off(null, null, component)

  BackboneMixin = (optionsOrPropName, customChangeOptions) ->
    if typeof optionsOrPropName is 'object'
      customChangeOptions = optionsOrPropName.renderOn
      propName = optionsOrPropName.propName
      modelOrCollection = optionsOrPropName.modelOrCollection
    else
      propName = optionsOrPropName
    unless modelOrCollection
      modelOrCollection = (props) ->
        props[propName]

    componentDidMount: ->
      # Whenever there may be a change in the Backbone data, trigger a reconcile.
      subscribe this, modelOrCollection(@props), customChangeOptions

    componentWillReceiveProps: (nextProps) ->
      return if modelOrCollection(@props) is modelOrCollection(nextProps)
      unsubscribe this, modelOrCollection(@props)
      subscribe this, modelOrCollection(nextProps), customChangeOptions
      @componentWillChangeModel?()

    componentDidUpdate: (prevProps, prevState) ->
      return if modelOrCollection(@props) is modelOrCollection(prevProps)
      @componentDidChangeModel?()

    componentWillUnmount: ->
      # Ensure that we clean up any dangling references when the component is destroyed.
      unsubscribe this, modelOrCollection(@props)
