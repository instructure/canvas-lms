define [
  'i18n!submission_details_dialog'
  'jquery'
  'jst/SubmissionDetailsDialog'
  'jst/_submission_detail' # a partial needed by the SubmissionDetailsDialog template
  'jst/_turnitinScore' # a partial needed by the submission_detail partial
  'jquery.ajaxJSON'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
  'jqueryui/dialog'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.scrollTo'
], (I18n, $, submissionDetailsDialog) ->

  class SubmissionDetailsDialog
    constructor: (@assignment, @student, @options) ->
      @url = @options.change_grade_url.replace(":assignment", @assignment.id).replace(":submission", @student.id)
      @submission = $.extend {}, @student["assignment_#{@assignment.id}"],
        assignment: @assignment
        speedGraderUrl: "#{@options.context_url}/gradebook/speed_grader?assignment_id=#{@assignment.id}#%7B%22student_id%22%3A#{@student.id}%7D"
        loading: true
      @dialog = $('<div class="use-css-transitions-for-show-hide" style="padding:0;"/>')
      @dialog.html(submissionDetailsDialog(@submission))
        .dialog
          title: @student.name
          width: 600
          resizable: false
          open: @scrollCommentsToBottom
        .delegate 'select', 'change', (event) =>
          @dialog.find('.submission_detail').each (index) ->
            $(this).showIf(index == event.currentTarget.selectedIndex)
        .delegate '.submission_details_add_comment_form', 'submit', (event) =>
          event.preventDefault()
          $(event.currentTarget).disableWhileLoading $.ajaxJSON @url, 'PUT', $(event.currentTarget).getFormData(), (data) =>
            @update(data)
            setTimeout =>
              @dialog.dialog('close')
            , 500

      deferred = $.ajaxJSON @url+'?include[]=submission_history&include[]=submission_comments&include[]=rubric_assessment', 'GET', {}, @update
      @dialog.find('.submission_details_comments').disableWhileLoading deferred

    open: =>
      @dialog.dialog('open')

    scrollCommentsToBottom: =>
      @dialog.find('.submission_details_comments').scrollTop(999999)

    update: (newData) =>
      $.extend @submission, newData
      @submission.submission_history[0] = @submission
      @submission.moreThanOneSubmission = @submission.submission_history.length > 1
      @submission.loading = false
      for submission in @submission.submission_history
        submission["submission_type_is#{submission.submission_type}"] = true
        submission.submissionWasLate = @assignment.due_at && new Date(@assignment.due_at) > new Date(submission.submitted_at)
        for comment in submission.submission_comments || []
          comment.url = "#{@options.context_url}/users/#{comment.author_id}"
          urlPrefix = "#{location.protocol}//#{location.host}"
          comment.image_url = "#{urlPrefix}/images/users/#{comment.author_id}?fallback=#{encodeURIComponent(urlPrefix+'/images/messages/avatar-50.png')}"
        for attachment in submission.attachments || []
          if turnitinDataForThisAttachment = submission.turnitin_data?["attachment_#{attachment.id}"]
            if turnitinDataForThisAttachment["similarity_score"]
              attachment.turnitin_data = turnitinDataForThisAttachment
              attachment.turnitin_data.state = "#{turnitinDataForThisAttachment.state || 'no'}_score"
              attachment.turnitin_data.score = "#{turnitinDataForThisAttachment.similarity_score}%"
              attachment.turnitin_data.reportUrl = "#{@options.context_url}/assignments/#{@assignment.id}/submissions/#{@student.id}/turnitin/attachment_#{attachment.id}"
              attachment.turnitin_data.tooltip = I18n.t('turnitin.tooltip.score', 'Turnitin Similarity Score - See detailed report')
      @dialog.html(submissionDetailsDialog(@submission))
      @dialog.find('select').trigger('change')
      @scrollCommentsToBottom()

    @cachedDialogs: {}

    @open: (assignment, student, options) ->
      (SubmissionDetailsDialog.cachedDialogs["#{assignment.id}-#{student.id}"] ||= new SubmissionDetailsDialog(assignment, student, options)).open()

