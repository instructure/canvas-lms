define ['ember'], (Ember) ->

  Environment = Ember.Object.extend

    setEnv: (env) ->
      @set('env', env)

    courseId: (->
      if @get('env')
        @get('env').context_asset_string.split('_')[1]
      else
        0
    ).property('env')

    canUpdate: ( ->
      return false unless @permissionsAvailable()
      @get('env').PERMISSIONS.update
    ).property('env')

    canManage: ( ->
      return false unless @permissionsAvailable()
      @get('env').PERMISSIONS.manage
    ).property('env')

    permissionsAvailable: ->
      !!(@get('env') && @get('env').PERMISSIONS)

  Environment.create()
