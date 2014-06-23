define [
  './application_adapter'
], (AppAdapter) ->

  ConversationAdapter = AppAdapter.extend
    namespace: 'api/v1'
