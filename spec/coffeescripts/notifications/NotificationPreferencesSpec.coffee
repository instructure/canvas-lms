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

  test 'policyCellProps with email', ->
    options = { update_url: "/profile/communication_update" }
    nps = new NotificationPreferences(options)
    category = {category: "helloworld"}
    channel = {type: "email", id: 42}
    props = nps.policyCellProps(category, channel)
    equal(props.buttonData.length, 4)

  test 'policyCellProps with sms', ->
    options = { update_url: "/profile/communication_update" }
    nps = new NotificationPreferences(options)
    category = {category: "helloworld"}
    channel = {type: "sms", id: 42}
    props = nps.policyCellProps(category, channel)
    equal(props.buttonData.length, 2)

  test 'policyCellProps with twitter', ->
    options = { update_url: "/profile/communication_update" }
    nps = new NotificationPreferences(options)
    category = {category: "helloworld"}
    channel = {type: "twitter", id: 42}
    props = nps.policyCellProps(category, channel)
    equal(props.buttonData.length, 2)

  test 'policyCellProps with sms', ->
    options = { update_url: "/profile/communication_update" }
    nps = new NotificationPreferences(options)
    category = {category: "helloworld"}
    channel = {type: "sms", id: 42}
    props = nps.policyCellProps(category, channel)
    equal(props.buttonData.length, 2)
