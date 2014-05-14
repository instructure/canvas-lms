define ['../shared/environment'], (env) ->
  window.ENV = {
    context_asset_string: 'course_1',
    PERMISSIONS: {
      manage: false,
      update: false,
    }
  }
  env.setEnv ENV
