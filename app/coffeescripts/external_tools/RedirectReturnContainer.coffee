define [
  'jquery'
], ($) ->

  class RedirectReturnContainer
    # TODO: make this more general, so it can work for more than just the content migration redirect
    attachLtiEvents: ->
      $(window).on 'externalContentReady', @_contentReady
      $(window).on 'externalContentCancel', @_contentCancel

    _contentReady: (event, data) =>
      @createMigration(data.url)

    _contentCancel: (event, data) =>
      location.href = "/courses/#{ENV.course_id}"

    createMigration: (file_url) ->
      data =
        migration_type: 'canvas_cartridge_importer'
        settings:
          file_url: file_url

      migrationUrl = "/api/v1/courses/#{ENV.course_id}/content_migrations"
      $.ajaxJSON migrationUrl, "POST", data, @redirectToMigrationsPage, @handleError

    redirectToMigrationsPage: ->
      location.href = "/courses/#{ENV.course_id}/content_migrations"

    handleError: (data) ->
      $.flashError data.message