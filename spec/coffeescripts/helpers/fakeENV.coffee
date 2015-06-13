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

    window.ENV = _.extend(defaults, options)

  teardown: -> window.ENV = {}
