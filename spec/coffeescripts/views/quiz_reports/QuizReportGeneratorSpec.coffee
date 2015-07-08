define [
  'jquery'
  'underscore'
  'compiled/views/quiz_reports/QuizReportGenerator'
  'compiled/models/QuizReport'
  'compiled/models/Progress'
], ($, _, View, QuizReport, Progress) ->
  module 'QuizReportGenerator',
    setup: ->

    teardown: ->
      @subject?.remove()
      @server?.restore()

    ajaxFixture: (method, url, status, body) ->
      spy = sinon.spy()

      @server.respondWith method, url, (request) ->
        spy()
        request.respond status,
          { 'Content-Type': 'application/json' },
          JSON.stringify(body)

      spy


  test 'it shows a link to generate the report', ->
    @quizReport = new QuizReport({
      id: 1,
      generatable: true
    })

    @subject = new View({ model: @quizReport })
    @subject.render()

    equal @subject.$('.create-report').length, 1

  test 'it does not allow the generation of item analysis reports in surveys', ->
    @quizReport = new QuizReport({
      generatable: false
    })

    @subject = new View({ model: @quizReport })
    @subject.render()

    equal @subject.$('.create-report').length, 0
    equal @subject.$('.btn.disabled').length, 1

  test 'it requests a report to be generated', ->
    @quizReport = new QuizReport({
      id: 1,
      report_type: 'student_analysis'
      generatable: true,
      url: '/api/v1/courses/1/quizzes/1/reports/1'
    })

    @server = sinon.fakeServer.create()
    saveSpy = sinon.spy(@quizReport, 'save')
    ajaxSpy = @ajaxFixture 'POST', '/api/v1/courses/1/quizzes/1/reports', 200, {}

    @subject = new View({ model: @quizReport })
    @subject.render()
    @subject.$('.create-report').click()
    ok saveSpy.called, 'it saves the report'
    @server.respond()
    ok ajaxSpy.called, 'it requests a report to be generated'

  test 'it shows a download report link when report is already generated', ->
    @quizReport = new QuizReport({
      id: 1,
      report_type: 'student_analysis'
      generatable: true,
      file: {
        id: 1,
        url: '/files/168/download'
      }
    })

    @subject = new View({ model: @quizReport })
    @subject.render()
    ok !@subject.$('.create-report').length
    ok @subject.$('a.btn').text().match(/download/i)
    equal @subject.$('a.btn').attr('href'), '/files/168/download'

  test 'it changes link from generate to download when generation is complete', ->
    @quizReport = new QuizReport({
      id: 1,
      generatable: true,
      report_type: 'student_analysis'
      url: '/api/v1/courses/1/quizzes/1/reports/1'
    })

    @server = sinon.fakeServer.create()
    saveSpy = sinon.spy(@quizReport, 'save')
    ajaxSpy = @ajaxFixture 'POST', '/api/v1/courses/1/quizzes/1/reports', 200, {
      file: {
        id: 1,
        url: '/files/168/download'
      }
    }

    @subject = new View({ model: @quizReport })
    @subject.render()
    @subject.$('.create-report').click()
    @subject.autoDownload = false
    ok saveSpy.called, 'it saves the report'

    @server.respond()
    @quizReport.trigger 'progressResolved'
    ok ajaxSpy.called, 'it requests a report to be generated'

    ok !@subject.$('.create-report').length, 're-renders once the report is generated'
    ok @subject.$('a.btn .icon-download').length, 'shows the download link'

  test 'it updates the progress-bar', ->
    @quizReport = new QuizReport({
      id: 1
      report_type: 'student_analysis'
      generatable: true
    })

    @subject = new View({ model: @quizReport })
    @subject.render()

    ok !@subject.$('.progress .bar').length, 'pbar is hidden'

    @quizReport.progressModel.set({ id: 1, completion: 0 })
    ok @subject.$('.progress .bar').length, 'pbar is shown'
    ok @subject.$('.progress .bar').attr('style').match(/width.*0/), 'pbar is empty'
    @quizReport.progressModel.set({ completion: 25 })
    ok @subject.$('.progress .bar').attr('style').match(/width.*25/), 'pbar gets updated'
