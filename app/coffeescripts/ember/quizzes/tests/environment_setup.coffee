define ['../shared/environment'], (env) ->
  window.ENV = {
    context_asset_string: 'course_1',
    PERMISSIONS: {
      manage: false,
      update: false,
    }
  }
  env.setEnv ENV

  {
    setUserPermissions: (canManage, canUpdate) ->
        prevContextAsset = env.get('env').context_asset_string
        env.setEnv
          context_asset_string: prevContextAsset
          PERMISSIONS:
            manage: canManage
            update: canUpdate
        env
  }
