require [
  'Backbone'
  'jquery'
  'str/htmlEscape'
  'compiled/tinymce'
  'compiled/jquery/validate'
  'tinymce.editor_box'
], ({View}, $, htmlEscape) ->

  class ProfileShow extends View

    el: document.body

    events:
      'click [data-event]': 'handleDeclarativeClick'
      'submit #edit_profile_form': 'validateForm'

    handleDeclarativeClick: (event) ->
      event.preventDefault()
      $target = $ event.currentTarget
      method = $target.data 'event'
      @[method]? event, $target

    ##
    # first run initializes some stuff, then is reassigned
    # to a showEditForm
    editProfile: ->
      @initEdit()
      @editProfile = @showEditForm

    showEditForm: ->
      @$el.addClass('editing').removeClass('not-editing')
      @$('.profile_links').removeClass('span6')

    initEdit: ->
      if @options.links?.length
        @addLinkField(null, null, title, url) for {title, url} in @options.links
      else
        @addLinkField()
        @addLinkField()

      # setTimeout so tiny has some width to read
      #setTimeout -> @$('#profile_bio').editorBox()
      @showEditForm()

    cancelEditProfile: ->
      @$el.addClass('not-editing').removeClass('editing')
      @$('.profile_links').addClass('span6')

    ##
    # Event handler that can also be called manually.
    # When called manually, it will focus the first input in the new row
    addLinkField: (event, $el, title = '', url = '') ->
      @$linkFields ?= @$ '#profile_link_fields'
      $row = $ """
        <tr>
          <td><input type="text" maxlength="255" name="link_titles[]" value="#{htmlEscape title}"></td>
          <td>→</td>
          <td><input type="text" name="link_urls[]" value="#{htmlEscape url}"></td>
          <td><a href="#" data-event="removeLinkRow"><i class="icon-end"></i></a></td>
        </tr>
      """
      @$linkFields.append $row

      # focus if called from the "add row" button
      if event?
        event.preventDefault()
        $row.find('input:first').focus()

    removeLinkRow: (event, $el) ->
      $el.parents('tr').remove()

    validateForm: (event) ->
      unless $('#edit_profile_form').validate()
        event.preventDefault()

  new ProfileShow ENV.PROFILE

