define [
  'i18n!developer_keys'
  'jquery'
  'jst/developer_key'
  'jst/developer_key_form'
  'compiled/fn/preventDefault'
  'jquery.ajaxJSON'
  'jquery.instructure_date_and_time'
  'jqueryui/dialog'
], (I18n, $, developer_key, developer_key_form, preventDefault) ->
  page = 0
  buildKey = (key) ->
    key.icon_image_url = key.icon_url || "/images/blank.png"
    key.name ||= I18n.t('unnamed_tool', "Unnamed Tool")
    key.user_name ||= I18n.t('no_user', "No User")
    key.created = $.parseFromISO(key.created_at).datetime_formatted
    key.last_auth = $.parseFromISO(key.last_auth_at).datetime_formatted
    key.last_access = $.parseFromISO(key.last_access_at).datetime_formatted
    $key = $(developer_key(key));
    $key.data('key', key)
    
  buildForm = (key, $orig) ->
    $form = $(developer_key_form(key || {}))
    $form.formSubmit({
      beforeSubmit: ->
        $("#edit_dialog button.submit").text(I18n.t('button.saving', "Saving Key..."))
      disableWhileLoading: true
      success: (key) ->
        $("#edit_dialog").dialog('close')
        $key = buildKey(key)
        if $orig
          $orig.after($key).remove()
        else
          $("#keys tbody").prepend($key)
      error: ->
        $("#edit_dialog button.submit").text(I18n.t('button.saving_failed', "Saving Key Failed"))
    })
    return $form
  nextPage = ->
    $("#loading").attr('class', 'loading')
    page++
    req = $.ajaxJSON('/api/v1/developer_keys?page=' + page, 'GET', {}, (data) ->
      for key in data
        $key = buildKey(key)
        $("#keys tbody").append($key)
      if req.getAllResponseHeaders().match /rel="next"/ 
        if page > 1
          nextPage()
        else
          $("#loading").attr('class', 'show_more')
      else
        $("#loading").attr('class', '')
    )
  nextPage()
  $("#keys").on('click', '.delete_link', preventDefault ->
    $key = $(this).closest(".key")
    key = $key.data('key')
    $key.confirmDelete({
      url: "/api/v1/developer_keys/" + key.id,
      message: I18n.t('messages.confirm_delete', 'Are you sure you want to delete this developer key?'),
      success: ->
        $key.remove()
    })
  ).on('click', '.edit_link', preventDefault ->
    $key = $(this).closest(".key")
    key = $key.data('key')
    $form = buildForm(key, $key)
    $("#edit_dialog").empty().append($form).dialog('open')
  )
  $(".add_key").click((event) ->
    event.preventDefault()
    $form = buildForm()
    $("#edit_dialog").empty().append($form).dialog('open')
  )
  $("#edit_dialog").html(developer_key_form({})).dialog({
    autoOpen: false,
    width: 350
  }).on('click', '.cancel', () ->
    $("#edit_dialog").dialog('close')
  )
  $(".show_all").click (event) ->
    nextPage()