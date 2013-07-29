define [], ->
  class ModuleItemViewRegister

    # Hash of registered views. You can look up any
    # view by it's key.
    # @api public

    @views = {}

    # Register a view by giving it a key and the view. 
    # Expects a view instance.
    # @api public

    @register: (options) ->
      key = options?.key
      view = options?.view

      @views[key] = view
