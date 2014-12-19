define [
  'jquery'
  'underscore'
  'Backbone'
  'jst/roles/permissionButton'
], ($, _, Backbone, template) ->
  class PermissionButtonView extends Backbone.View
    template: template
    tagName: 'td'
    className: 'permissionButtonView'

    events: 
      "change input[type=radio]" : "updateRole"

    # Method Summary:
    #   Set the permission_name attribute. 
    #
    # ============================================================================
    #  !!! NOTE permission_name This must be passed in for this view to work !!!
    # ============================================================================
    #
    # @api backbone override
    initialize: -> 
      super
      @permission_name = @options.permission_name if @options.permission_name

    # Method Summary
    #   We add a few values to the json being passed into the template so we can determine which item 
    #   should be selected on the initial page load. We didn't create a helper for handlebars because
    #   this is very specific to this class. We have some logic here that checks to see what the 
    #   permissions value is given it's key, the permission_name for some of the properties. Permissions
    #   object might look like this.
    #
    #   ie: 
    #       "enabled": true,
    #       "locked": true,
    #       "readonly": false,
    #       "explicit": true,
    #       "prior_default": false
    #
    # @api custom backbone override
    toJSON: -> 
      json = super

      json['enableChecked'] = @isEnabled()
      json['enableAndLockChecked'] = @isEnabledAndLocked() 
      json['disableChecked'] = @isDisabled()
      json['disableAndLockChecked'] = @isDisabledAndLocked()
      json['systemDefaultChecked'] = @isDefault()
      json['systemDefaultLockedChecked'] = @isDefaultAndLocked()
      json['readOnly'] = @isReadOnly()
      json['default'] = @isDefault() || @isDefaultAndLocked() # Any kind of default. Used for setting a css class
      json['addDefaultTitle'] = @isDefault() || @isDefaultAndLocked() && !@isReadOnly()

      json

    # Method Summary
    #   Make sure all initial icons are shown correctly. Puts the correct 
    #   set of icons into the button by cloning the icons in the dropdown 
    #   list. :) I'm a smarty pants. Also, add accessibility attributes.
    #   Each button has data about it's role and permission name. This 
    #   makes testing easier.
    #   TODO Refactor adding data attributes and titles into their own functions.
    # @api custom backbone override 
    afterRender: ->
      @setPreviewIcons()
      @setDataAttributes()
      @setTooltips()

    # Method Summary
    #   After the button loads, this adds data attribute to each button
    #   so you know what role and permission each button is associated
    #   with
    # @api private
    setDataAttributes: -> 
      @$el.attr 'data-role_id', @model.id
      @$el.attr 'data-permission_name', @permission_name

    # Method Summary
    #   After the button loads, this adds tooltips to each of the icons 
    #   so when you hover over the icons it will tell you what it's set 
    #   to.
    # @api private
    setTooltips: -> 
      @$el.find('.icon-check').attr('title', 'Enabled').attr('data-tooltip', "") if !@isReadOnly()
      @$el.find('.icon-x').attr('title', 'Disabled').attr('data-tooltip', "") if !@isReadOnly()
      @$el.find('.icon-lock').attr('title', 'Locked').attr('data-tooltip', "") if !@isReadOnly()

    # Method Summary
    #   Preview Icons are set based on the model attributes, not what is 
    #   selected; however model attributes should always be in sync with
    #   what is selected so it will have the same effect. There are only
    #   6 possiblities.
    # @api private
    setPreviewIcons: -> 
      if @isEnabled() then @setEnabledIcon()
      else if @isEnabledAndLocked() then @setEnabledLockedIcon()
      else if @isDisabled() then @setDisabledIcon()
      else if @isDisabledAndLocked() then @setDisabledLockedIcon()
      else if @isDefault() then @setDefaultIcon()
      else if @isDefaultAndLocked() then @setDefaultAndLockedIcon()

    # Method Summary: 
    #   We are checking the ides of each changed radio element because we 
    #   can't get access to @cid inside of the "events" object. If somone
    #   can figure out how to do this feel free to remove this switch
    #   statement. 
    #
    #   TODO Remove the 'default_permission' its ugly
    # @api private
    updateRole: (event) -> 
      event.preventDefault()

      switch $(event.target).attr('id')
        when "button-#{@cid}-0"
          @$el.find('a.btn').removeClass 'default_permission'
          @enable()
          break
        when "button-#{@cid}-1"
          @$el.find('a.btn').removeClass 'default_permission'
          @enableAndLock()
          break
        when "button-#{@cid}-2"
          @$el.find('a.btn').removeClass 'default_permission'
          @disable()
          break
        when "button-#{@cid}-3"
          @$el.find('a.btn').removeClass 'default_permission'
          @disableAndLock()
          break
        when "button-#{@cid}-4"
          @$el.find('a.btn').addClass 'default_permission'
          @setSystemDefault()
          break
        when "button-#{@cid}-5"
          @$el.find('a.btn').addClass 'default_permission'
          @setSystemDefaultAndLocked()
          break

      @setPreviewIcons()
      @closeMenu()
      @saveModel()
    
    # Method Summary
    #   Save the current role by calling .save.
    # @api private
    saveModel: -> 
      @model.save {},
        failure: -> 
          alert 'Permission was not be saved!'

    # Method Summary
    #   Close the menu by removing the 'open' class on it's parent btn-group
    # @api private
    closeMenu: -> 
      @$el.children('.btn-group').removeClass 'open'

    # Method Summary for enable, enableAndLock, disable, disableAndLock
    #   When called, this enables the given role for this buttons property. 
    #   Enabling a property should look like the following
    #
    #   some_property: 
    #     "enabled": true
    #     "locked" : false
    #     "explicit" : true
    # @api private
    enable: ->
      @model.get('permissions')[@permission_name].enabled = true
      @model.get('permissions')[@permission_name].explicit = true
      @model.get('permissions')[@permission_name].locked = false

    enableAndLock: -> 
      @model.get('permissions')[@permission_name].enabled = true
      @model.get('permissions')[@permission_name].explicit = true
      @model.get('permissions')[@permission_name].locked = true

    disable: -> 
      @model.get('permissions')[@permission_name].enabled = false
      @model.get('permissions')[@permission_name].explicit = true
      @model.get('permissions')[@permission_name].locked = false

    disableAndLock: -> 
      @model.get('permissions')[@permission_name].enabled = false
      @model.get('permissions')[@permission_name].explicit = true
      @model.get('permissions')[@permission_name].locked = true

    # Method Summary
    #   This is the edge case for setting properties. This does care what
    #   the other properties were set to because when you set explict to
    #   false and save it, the request comming back will tell you what 
    #   the prior default (either enabled or disabled) is. If no prior 
    #   default is set, then you can assume what the permission is based
    #   on the properites sent back. For example, just use the enabled 
    #   field. 
    #
    #   Example of the response that will be generated from setting 
    #   explicit to false: 
    #
    #   ie: 
    #       "enabled": true,
    #       "locked": true,
    #       "readonly": false,
    #       "explicit": true,
    #       "prior_default": false
    #
    # @api private
    setSystemDefault: -> 
      @model.get('permissions')[@permission_name].locked = false
      @model.get('permissions')[@permission_name].explicit = false

    # Method Summary
    #   Same as systemDefault except locked is true.
    # @api private
    setSystemDefaultAndLocked: -> 
      @model.get('permissions')[@permission_name].locked = true
      @model.get('permissions')[@permission_name].explicit = false
    
    # Method Summary
    #   Check to see if this role is enabled. 
    #
    #   This means 
    #
    #     enabled : true
    #     locked : false
    #     explicit : true
    #
    #   returns Boolean
    # @api private
    isEnabled: -> 
      @model.get('permissions')[@permission_name].enabled && !@isLocked() && @isExplicit()

    # Method Summary
    #   Check to see if this role is enabled and locked.
    #   
    #   This means
    #
    #     enabled : true
    #     locked : true
    #     explicit : true
    #     
    #   returns Boolean
    # @api private
    isEnabledAndLocked: -> 
      @model.get('permissions')[@permission_name].enabled && @isLocked() && @isExplicit()

    # Method Summary
    #   Check to see if this role is disabled.
    #   
    #   This means
    #
    #     enabled : false
    #     locked : false
    #     explicit : true
    #     
    #   returns Boolean
    # @api private
    isDisabled: -> 
      !@model.get('permissions')[@permission_name].enabled && !@isLocked() && @isExplicit()

    # Method Summary
    #   Check to see if this role is disabled and locked.
    #
    #   This means
    #
    #     enabled : false
    #     locked : true
    #     explicit : true
    #
    #   returns Boolean
    # @api private
    isDisabledAndLocked: -> 
      !@model.get('permissions')[@permission_name].enabled && @isLocked() && @isExplicit()

    # Method Summary
    #   All default means is explicit is set to false and lock is false.
    #
    #   This means 
    #
    #     enabled : 'don't care about this value :/'
    #     locked : false
    #     explicit : false
    #
    # @api private
    isDefault: -> 
      !@isExplicit() && !@isLocked()

    # Method Summary
    #   Default and lock does is make sure explicit is set to false and lock is true
    #
    #   This means 
    #
    #     enabled : 'don't care about this value :/'
    #     locked : true
    #     explicit : false
    #     
    # @api private 
    isDefaultAndLocked: -> 
      !@isExplicit() && @isLocked()
    
    # Method Summary
    #   Read only attribute is set means you cannot change this permission.
    #
    #   This means 
    #
    #   readonly : true
    #
    # @api private
    isReadOnly: -> 
      @model.get('permissions')[@permission_name].readonly

    # Method Summary
    # Checks to see if the permission is explicit. Doesn't care about any other permissions.
    #   ie: 
    #     explicit : true | false
    #
    # @api private
    isExplicit: -> 
      @model.get('permissions')[@permission_name].explicit

    # Method Summary
    #   Checks to see if the permission is locked. Doesn't care about any other permissions
    #
    #   ie: 
    #     locked : true | false
    # @api private
    isLocked: -> 
      @model.get('permissions')[@permission_name].locked

    # Method Summary
    #   Set icon button for preview. In order to do this we just clone the radio buttons
    #   images into the buttons preview section. Takes in a string. The string can have these options
    #   0 = "enabled"
    #   1 = "enabledLocked"
    #   2 = "disabled"
    #   3 = "disabledLocked"
    # @api private
    setButtonPreview: (selected_radio) -> 
      icons = @$el.find("label[for=button-#{@cid}-#{selected_radio}] i").clone()
      @$el.find('a.dropdown-toggle').html icons

    # Method Summary
    #   Sets the button preview for an dropdown button to the enabled icons
    # @api private
    setEnabledIcon: -> 
      @setButtonPreview 0

    # Method Summary
    #   Sets the button preview for an dropdown button to the enabled and locked icons
    # @api private
    setEnabledLockedIcon: -> 
      @setButtonPreview 1

    # Method Summary
    #   Sets the button preview for an dropdown button to the disabled
    # @api private
    setDisabledIcon: -> 
      @setButtonPreview 2

    # Method Summary
    #   Sets the button preview for an dropdown button to the disabled
    # @api private
    setDisabledLockedIcon: -> 
      @setButtonPreview 3

    # Method Summary
    #   Check to see if there is a prior_set because if there is one set, we should always
    #   use that setting to show what the default is. If that setting is not set, we can
    #   assume its just the enabled value.
    # @api private
    setDefaultIcon: -> 
      if _.isUndefined @model.get('permissions')[@permission_name].prior_default
        if @model.get('permissions')[@permission_name].enabled then @setEnabledIcon() else @setDisabledIcon()
      else
        if @model.get('permissions')[@permission_name].prior_default then @setEnabledIcon() else @setDisabledIcon()

    # Method Summary
    #   Same as setDefaultIcon except everything has a lock applied to it.
    # @api private
    setDefaultAndLockedIcon: -> 
      if _.isUndefined @model.get('permissions')[@permission_name].prior_default
        if @model.get('permissions')[@permission_name].enabled then @setEnabledLockedIcon() else @setDisabledLockedIcon()
      else
        if @model.get('permissions')[@permission_name].prior_default then @setEnabledLockedIcon() else @setDisabledLockedIcon()
