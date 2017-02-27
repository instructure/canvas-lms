define [
  'Backbone'
  'compiled/models/DateGroup'
], (Backbone, DateGroup) ->

  QUnit.module 'DateGroup',
    setup: ->

  test 'default title is set', ->
    dueAt = new Date("2013-08-20 11:13:00")
    model = new DateGroup(due_at: dueAt, title: "Summer session")
    equal model.get("title"), 'Summer session'

    model = new DateGroup(due_at: dueAt)
    equal model.get("title"), 'Everyone else'


  test "#dueAt parses due_at to a date", ->
    model = new DateGroup(due_at: "2013-08-20 11:13:00")
    equal model.dueAt().constructor, Date

  test "#dueAt doesn't parse null date", ->
    model = new DateGroup(due_at: null)
    equal model.dueAt(), null


  test "#unlockAt parses unlock_at to a date", ->
    model = new DateGroup(unlock_at: "2013-08-20 11:13:00")
    equal model.unlockAt().constructor, Date

  test "#unlockAt doesn't parse null date", ->
    model = new DateGroup(unlock_at: null)
    equal model.unlockAt(), null


  test "#lockAt parses lock_at to a date", ->
    model = new DateGroup(lock_at: "2013-08-20 11:13:00")
    equal model.lockAt().constructor, Date

  test "#lockAt doesn't parse null date", ->
    model = new DateGroup(lock_at: null)
    equal model.lockAt(), null


  test "#alwaysAvailable if both unlock and lock dates aren't set", ->
    model = new DateGroup(unlock_at: null, lock_at: null)
    ok model.alwaysAvailable()

  test "#alwaysAvailable is false if unlock date is set", ->
    model = new DateGroup(unlock_at: "2013-08-20 11:13:00", lock_at: null)
    ok !model.alwaysAvailable()

  test "#alwaysAvailable is false if lock date is set", ->
    model = new DateGroup(unlock_at: null, lock_at: "2013-08-20 11:13:00")
    ok !model.alwaysAvailable()


  test "#available is true if always available", ->
    model = new DateGroup(unlock_at: null, lock_at: null)
    ok model.available()

  test "#available is true if no lock date and unlock date has passed", ->
    model = new DateGroup(unlock_at: "2013-08-20 11:13:00", now: "2013-08-30 00:00:00")
    ok model.available()

  test "#available is false if not unlocked yet", ->
    model = new DateGroup(unlock_at: "2013-08-20 11:13:00", now: "2013-08-19 00:00:00")
    ok !model.available()

  test "#available is false if locked", ->
    model = new DateGroup(lock_at: "2013-08-20 11:13:00", now: "2013-08-30 00:00:00")
    ok !model.available()


  test "#pending is true if not unlocked yet", ->
    model = new DateGroup(unlock_at: "2013-08-20 11:13:00", now: "2013-08-19 00:00:00")
    ok model.pending()

  test "#pending is false if no unlock date", ->
    model = new DateGroup(unlock_at: null)
    ok !model.pending()

  test "#pending is false if unlocked", ->
    model = new DateGroup(unlock_at: "2013-08-20 11:13:00", now: "2013-08-30 00:00:00")
    ok !model.pending()


  test "#open is true if has a lock date but not locked yet", ->
    model = new DateGroup(lock_at: "2013-08-20 11:13:00", now: "2013-08-10 00:00:00")
    ok model.open()

  test "#open is false without an unlock date", ->
    model = new DateGroup(unlock_at: null)
    ok !model.open()

  test "#open is false if not unlocked yet", ->
    model = new DateGroup(unlock_at: "2013-08-20 11:13:00", now: "2013-08-19 00:00:00")
    ok !model.open()


  test "#closed is true if not locked", ->
    model = new DateGroup(lock_at: "2013-08-20 11:13:00", now: "2013-08-30 00:00:00")
    ok model.closed()

  test "#closed is false if no lock date", ->
    model = new DateGroup(lock_at: null)
    ok !model.closed()

  test "#closed is false if unlocked has passed", ->
    model = new DateGroup(lock_at: "2013-08-20 11:13:00", now: "2013-08-19 00:00:00")
    ok !model.closed()


  test "#toJSON includes dueFor", ->
    model = new DateGroup(title: "Summer session")
    json  = model.toJSON()
    equal json.dueFor, "Summer session"

  test "#toJSON includes dueAt", ->
    model = new DateGroup(due_at: "2013-08-20 11:13:00")
    json  = model.toJSON()
    equal json.dueAt.constructor, Date

  test "#toJSON includes unlockAt", ->
    model = new DateGroup(unlock_at: "2013-08-20 11:13:00")
    json  = model.toJSON()
    equal json.unlockAt.constructor, Date

  test "#toJSON includes lockAt", ->
    model = new DateGroup(lock_at: "2013-08-20 11:13:00")
    json  = model.toJSON()
    equal json.lockAt.constructor, Date


  test "#toJSON includes available", ->
    model = new DateGroup
    json  = model.toJSON()
    equal json.available, true

  test "#toJSON includes pending", ->
    model = new DateGroup(unlock_at: "2013-08-20 11:13:00", now: "2013-08-19 00:00:00")
    json  = model.toJSON()
    equal json.pending, true

  test "#toJSON includes open", ->
    model = new DateGroup(lock_at: "2013-08-20 11:13:00", now: "2013-08-10 00:00:00")
    json  = model.toJSON()
    equal json.open, true

  test "#toJSON includes closed", ->
    model = new DateGroup(lock_at: "2013-08-20 11:13:00", now: "2013-08-30 00:00:00")
    json  = model.toJSON()
    equal json.closed, true
