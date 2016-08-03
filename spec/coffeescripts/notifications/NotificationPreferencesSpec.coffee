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

	test 'policyCellHtml with twitter', ->
		options = { update_url: "/profile/communication_update" }
		nps = new NotificationPreferences(options)
		category = {category: "helloworld"}
		channel = {type: "twitter"}
		inputs = $(nps.policyCellHtml(category, channel)).find("input").length
		equal(inputs, 2)

	test 'policyCellHtml with sms', ->
		options = { update_url: "/profile/communication_update" }
		nps = new NotificationPreferences(options)
		category = {category: "helloworld"}
		channel = {type: "sms"}
		inputs = $(nps.policyCellHtml(category, channel)).find("input").length
		equal(inputs, 2)
