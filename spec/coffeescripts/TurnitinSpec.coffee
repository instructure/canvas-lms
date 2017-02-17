define ['compiled/gradebook/Turnitin'], (Turnitin) ->

  submissionWithReport = null

  QUnit.module "Turnitin",
    setup: ->
      submissionWithReport =
        'id': '7'
        'body': null
        'url': null
        'grade': null
        'score': null
        'submitted_at': '2016-11-29T22:29:44Z'
        'assignment_id': '52'
        'user_id': '2'
        'submission_type': 'online_upload'
        'workflow_state': 'submitted'
        'grade_matches_current_submission': true
        'graded_at': null
        'grader_id': null
        'attempt': 1
        'excused': null
        'late': false
        'preview_url': 'http://canvas.docker/courses/2/assignments/52/submissions/2?preview=1&version=1'
        'turnitin_data': 'attachment_103':
          'similarity_score': 0.8
          'state': 'acceptable'
          'report_url': 'http://www.instructure.com'
          'status': 'pending'
        'has_originality_report': true
        'attachments': [ {
          'id': '103'
          'folder_id': '9'
          'display_name': 'Untitled-2.rtf'
          'filename': '1480456390_119__Untitled.rtf'
          'content-type': 'text/rtf'
          'url': 'http://canvas.docker/files/103/download?download_frd=1&verifier=kRS6CMQUNlpF1sobUbALPa0AxE2J70vxPAX7GQqo'
          'size': null
          'created_at': '2016-11-29T22:29:43Z'
          'updated_at': '2016-11-29T22:29:43Z'
          'unlock_at': null
          'locked': false
          'hidden': false
          'lock_at': null
          'hidden_for_user': false
          'thumbnail_url': null
          'modified_at': '2016-11-29T22:29:43Z'
          'mime_class': 'doc'
          'media_entry_id': null
          'locked_for_user': false
          'preview_url': null
        } ]
        'turnitin': {}

  test 'uses originality_report type in url if submission has an OriginalityReport', () ->
    tii_data = Turnitin.extractDataForTurnitin(submissionWithReport, 'attachment_103', '/courses/2')
    equal tii_data.reportUrl, '/courses/2/assignments/52/submissions/2/originality_report/attachment_103'

  test 'uses turnitin or vericite type if no OriginalityReport is present for the submission', () ->
    submissionWithoutReport = submissionWithReport
    submissionWithoutReport.has_originality_report = null
    tii_data = Turnitin.extractDataForTurnitin(submissionWithoutReport, 'attachment_103', '/courses/2')
    equal tii_data.reportUrl, '/courses/2/assignments/52/submissions/2/turnitin/attachment_103'

  test 'it uses vericite type if vericite data is present', () ->
    submissionWithReport.vericite_data = submissionWithReport.turnitin_data
    submissionWithReport.vericite_data.provider = 'vericite'
    delete submissionWithReport.turnitin_data
    delete submissionWithReport.has_originality_report
    tii_data = Turnitin.extractDataForTurnitin(submissionWithReport, 'attachment_103', '/courses/2')
    equal tii_data.reportUrl, '/courses/2/assignments/52/submissions/2/vericite/attachment_103'


