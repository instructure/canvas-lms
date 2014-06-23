define [
  'ember'
  'ember-qunit'
  'ic-ajax'
  '../../../../start_app'
  '../../../../environment_setup'
  '../../../../../controllers/quiz/statistics/summary/report_generator_controller'
  '../../../../../models/quiz_report'
], (Ember, emq, ajax, startApp, env, Controller, Model) ->

  {run} = Ember

  App = startApp()
  emq.setResolver(Ember.DefaultResolver.create({namespace: App}))

  FileFixture = {
    "id": 1,
    "content-type": "text/csv",
    "display_name": "CNVS-4338 Quiz Student Analysis Report.csv",
    "filename": "quiz_student_analysis_report.csv",
    "url": "/files/207/download?download_frd=1&verifier=ZoWW2Rut19EYVUnpaZngFadznCeu7uAWx8USvl8X",
    "size": 1807,
    "created_at": "2014-05-08T05:56:42Z",
    "updated_at": "2014-05-08T05:56:42Z",
    "unlock_at": null,
    "locked": false,
    "hidden": false,
    "lock_at": null,
    "hidden_for_user": false,
    "thumbnail_url": null,
    "locked_for_user": false
  }

  emq.moduleFor('controller:quiz_statistics_summary_report_generator',
    'QuizStatisticsSummaryReportGeneratorController', {
    setup: ->
      App = startApp()
      emq.setResolver(Ember.DefaultResolver.create({namespace: App}))
      container = App.__container__
      store = container.lookup 'store:main'
      run =>
        @model = store.createRecord('quiz_report', {
          id: 1
          url: '/quiz_reports/1'
        })
        @subject = this.subject()
        @subject.set('model', @model)
    teardown: ->
      ajax.raw.restore() if ajax.raw.restore
      run App, 'destroy'
    }
  )

  emq.test 'sanity', ->
    ok @subject
    equal @subject.get('model'), @model

  emq.test 'locking: it rejects calls to #generate when locked', ->
    ajaxSpy = sinon.stub(ajax, 'raw').returns(Ember.RSVP.defer().promise)
    lockSpy = sinon.spy(@subject, 'lock')

    @subject.send('generate')

    ok ajaxSpy.calledOnce
    ok lockSpy.calledOnce
    ok @subject.get('isLocked')

    @subject.send('generate')

    ok ajaxSpy.calledOnce

  emq.test 'locking: it unlocks once the generation is done, regardless of status', ->
    service = Ember.RSVP.defer()
    ajaxSpy = sinon.stub(ajax, 'raw').returns(service.promise)
    lockSpy = sinon.spy(@subject, 'lock')

    @subject.send('generate')

    ok @subject.get('isLocked')

    run -> service.reject()

    ok !@subject.get('isLocked')

  emq.test '#pullGeneratedReport: it reloads and auto-downloads', ->
    expect 3

    ajax.defineFixture '/quiz_reports/1?include[]=file', response: {
      quiz_reports: [{
        id: 1,
        file: FileFixture
      }]
    }

    autoDownloadSpy = sinon.stub(@subject, 'triggerDownload')

    Ember.run =>
      equal @model.get('file.id'), undefined
      @subject.autoDownload = true
      @subject.pullGeneratedReport().then =>
        equal @model.get('file.id'), 1
        ok autoDownloadSpy.called, 'it triggers the download'

  emq.test "#pullGeneratedReport: it reloads but doesn't auto-download", ->
    expect 3

    ajax.defineFixture '/quiz_reports/1?include[]=file', response: {
      quiz_reports: [{
        id: 1,
        file: FileFixture
      }]
    }

    autoDownloadSpy = sinon.stub(@subject, 'triggerDownload')

    Ember.run =>
      equal @model.get('file.id'), undefined
      @subject.pullGeneratedReport().then =>
        equal @model.get('file.id'), 1
        ok !autoDownloadSpy.called, "it doesn't trigger the download"

