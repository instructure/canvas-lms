define ['compiled/handlebars_helpers', 'jquery'], (Handlebars, jQuery) ->

  # A client-side templating wrapper.  Templates are compiled with the rake task
  # `$ rake jst:compile` or automatically using the guard gem `$ guard`.
  # Don't call the templating object directly (like Handlebars), use this class.

  # export to window until we convert new stuff to modules
  class Template

    # If called w/o `new`, it will return the HTML string immediately.
    # i.e. `Template(test, {foo: 'bar'})` => '<div>bar</div>'
    #
    # If called with `new` it will return an instance.
    #
    # Arguments:
    #   @name (string):
    #     The id of template.  Examples [template path] => [id]:
    #       `app/views/jst/foo.handlebars` becomes `foo`
    #       `app/views/jst/foo/bar/baz.handlebars` becomes `foo/bar/baz`
    #
    #   @locals (object: optional):
    #     Object literal of key:value pairs for use as local vars in the template.
    #
    constructor: (@name, @locals) ->
      if this instanceof Template isnt true
        return new Template(name, locals).toHTML()

    # Generates an HTML string from the template.
    #
    # Arguments:
    #   locals (object: optional) - locals to use in the template, if omitted the
    #   instance locals property will be used.
    #
    # Returns:
    #   String - and HTML string
    toHTML: (locals = @locals) ->
      Handlebars.templates[@name](locals)

    # Creates an element rendered with the template.
    #
    # Arguments:
    #   locals (object: optional):
    #     locals to use in the template, if omitted the instance locals property
    #     will be used.
    #
    # Returns:
    #   jQuery Element Collection
    toElement: (locals) ->
      html = @toHTML locals
      jQuery('<div/>').html(html)
