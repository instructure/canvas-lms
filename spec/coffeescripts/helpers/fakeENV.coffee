define ['underscore'], (_) ->
  setup: (options = {}) ->
    if(!window.ENV) then window.ENV = {}

    defaults =
      current_user_id: 1
      current_user_roles: [ "user", "teacher", "admin", "student" ]
      current_user_cache_key: "users/1-20111116001415"
      context_asset_string: "user_1"
      domain_root_account_cache_key: "accounts/1-20111117224337"
      context_cache_key: "users/1-20111116001415"
      PERMISSIONS: {}
      GRADEBOOK_OPTIONS: {
        multiple_grading_periods_enabled: true
        latest_end_date_of_admin_created_grading_periods_in_the_past: 'Thu Jul 30 2015 00:00:00 GMT-0700 (PDT)'
      }

    window.ENV = _.extend(defaults, options)

  teardown: -> window.ENV = {}
