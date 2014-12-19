define [
  'Backbone'
  'jquery'
  'underscore'
  'compiled/fn/preventDefault'
  'str/htmlEscape'
  'jquery.toJSON'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
], (Backbone, $, _, preventDefault, htmlEscape) ->

  ValidatedMixin =

    ##
    # Errors are displayed relative to the field to which they belong. If
    # the key of the error in the response doesn't match the name attribute
    # of the form input element, configure a selector here.
    #
    # For example, given a form field like this:
    #
    #   <input name="user[first_name]">
    #
    # and an error response like this:
    #
    #   {errors: { first_name: {...} }}
    #
    # you would do this:
    #
    #   fieldSelectors:
    #     first_name: '[name=user[first_name]]'
    fieldSelectors: null

    findField: (field) ->
      selector = @fieldSelectors?[field] or "[name='#{field}']"
      $el = @$(selector)
      if $el.data('rich_text')
        $el = $el.next('.mceEditor').find(".mceIframeContainer")
      $el

    ##
    # Needs an errors object that looks like this:
    #
    #   {
    #     <field1>: [errors],
    #     <field2>: [errors]
    #   }
    #
    # For example:
    #
    #   {
    #     first_name: [
    #       {
    #         type: 'required'
    #         message: 'First name is required'
    #       },
    #       {
    #         type: 'no_numbers',
    #         message: "First name can't contain numbers"
    #       }
    #     ]
    #   }

    showErrors: (errors) ->
      for fieldName, field of errors
        $input = @findField fieldName
        # check for a translations option first, fall back to just displaying otherwise
        html = (htmlEscape(@translations?[message] or message) for {message} in field).join('</p><p>')
        $input.errorBox new htmlEscape.SafeString("<div>#{html}</div>")
        field.$input = $input
        field.$errorBox = $input.data 'associated_error_box'

