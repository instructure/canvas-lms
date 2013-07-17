define [
  'Backbone'
  'underscore'
], (Backbone, _) -> 
  class MigrationView extends Backbone.View
    
    # Validations for this view that should be made
    # on the client side before save.
    # ---------------------------------------------
    # @expects void
    # @returns ErrorMessage
    # @api private override ValidateFormView

    validateBeforeSave: => 
      # There might be a better way to do this with reduce
      validations = {}
      _.each @children, (child) => 
        _.extend(validations, child.validations()) if child.validations

      validations
