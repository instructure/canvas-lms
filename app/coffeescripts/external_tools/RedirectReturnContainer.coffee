define [
  'jquery'
], ($) ->

  class RedirectReturnContainer
    successUrl: ENV.redirect_return_success_url
    cancelUrl: ENV.redirect_return_cancel_url

    attachLtiEvents: ->
      $(window).on 'externalContentReady', @_contentReady
      $(window).on 'externalContentCancel', @_contentCancel

    _contentReady: (event, data) =>
      if data && data.return_type == "file"
        @createMigration(data.url)
      else
        @redirectToSuccessUrl()

    _contentCancel: (event, data) =>
      location.href = @cancelUrl

    redirectToSuccessUrl: =>
      location.href = @successUrl

    createMigration: (file_url) =>
      data =
        migration_type: 'canvas_cartridge_importer'
        settings:
          file_url: file_url

      migrationUrl = "/api/v1/courses/#{ENV.course_id}/content_migrations"
      $.ajaxJSON migrationUrl, "POST", data, @redirectToSuccessUrl, @handleError

    handleError: (data) ->
      $.flashError data.message