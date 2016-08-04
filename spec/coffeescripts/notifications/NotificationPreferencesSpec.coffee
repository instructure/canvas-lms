define [
  'compiled/notifications/NotificationPreferences'
], (NotificationPreferences) ->

	module "NotificationPreferences"

	test 'tooltip instance was added', ->
		options = { update_url: "/profile/communication_update" }
		nps = new NotificationPreferences(options)
		$np = $('#notification-preferences')
		freq = $np.find('.frequency')
		inst = $(freq).tooltip('instance')
		notEqual(inst, undefined)