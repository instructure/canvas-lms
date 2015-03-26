define [
  'i18n!submission_details_dialog'
  'jquery'
  'jst/SubmissionDetailsDialog'
  'compiled/gradebook2/Turnitin'
  'jst/_submission_detail' # a partial needed by the SubmissionDetailsDialog template
  'jst/_turnitinScore' # a partial needed by the submission_detail partial
  'jquery.ajaxJSON'
  'jquery.disableWhileLoading'
  'jquery.instructure_forms'
  'jqueryui/dialog'
  'jquery.instructure_misc_plugins'
  'vendor/jquery.scrollTo'
  'vendor/jquery.ba-tinypubsub'
], (I18n, $, submissionDetailsDialog, {extractDataFor}) ->

  class SubmissionDetailsDialog
    constructor: (@assignment, @student, @options) ->
      speedGraderUrl = if @options.speed_grader_enabled
        "#{@options.context_url}/gradebook/speed_grader?assignment_id=#{@assignment.id}#%7B%22student_id%22%3A#{@student.id}%7D"
      else
        null

      @url = @options.change_grade_url.replace(":assignment", @assignment.id).replace(":submission", @student.id)
      @submission = $.extend {}, @student["assignment_#{@assignment.id}"],
        inputName: 'submission[posted_grade]'
        assignment: @assignment
        speedGraderUrl: speedGraderUrl
        loading: true
        showPointsPossible: (@assignment.points_possible || @assignment.points_possible == '0') && @assignment.grading_type != "gpa_scale"
      @submission["assignment_grading_type_is_#{@assignment.grading_type}"] = true

      @$el = $('<div class="use-css-transitions-for-show-hide" style="padding:0;"/>')
      @$el.html(submissionDetailsDialog(@submission))

      @dialog = @$el.dialog
        title: @student.name
        width: 600
        resizable: false

      @dialog.delegate 'select', 'change', (event) =>
        @dialog.find('.submission_detail').each (index) ->
          $(this).showIf(index == event.currentTarget.selectedIndex)
      .delegate '.submission_details_grade_form', 'submit', (event) =>
        event.preventDefault()
        $(event.currentTarget.form).disableWhileLoading $.ajaxJSON @url, 'PUT', $(event.currentTarget).getFormData(), (data) =>
          @update(data)
          $.publish 'submissions_updated', [@submission.all_submissions]
          setTimeout =>
            @dialog.dialog('close')
          , 500
      .delegate '.submission_details_add_comment_form', 'submit', (event) =>
        event.preventDefault()
        $(event.currentTarget).disableWhileLoading $.ajaxJSON @url, 'PUT', $(event.currentTarget).getFormData(), (data) =>
          @update(data)
          setTimeout =>
            @dialog.dialog('close')
          , 500

      deferred = $.ajaxJSON @url+'&include[]=submission_history&include[]=submission_comments&include[]=rubric_assessment', 'GET', {}, @update
      @dialog.find('.submission_details_comments').disableWhileLoading deferred

    open: =>
      @dialog.dialog('open')
      @scrollCommentsToBottom()
      $('.ui-dialog-titlebar-close').focus()

    scrollCommentsToBottom: =>
      @dialog.find('.submission_details_comments').scrollTop(999999)

    update: (newData) =>
      $.extend @submission, newData
      @submission.moreThanOneSubmission = @submission.submission_history.length > 1
      @submission.loading = false
      for submission in @submission.submission_history
        for comment in submission.submission_comments || []
          comment.url = "#{@options.context_url}/users/#{comment.author_id}"
          urlPrefix = "#{location.protocol}//#{location.host}"
          comment.image_url = "#{urlPrefix}/images/users/#{comment.author_id}?fallback=#{encodeURIComponent(urlPrefix+'/images/messages/avatar-50.png')}"
        submission.turnitin = extractDataFor(submission, "submission_#{submission.id}", @options.context_url)
        for attachment in submission.attachments || []
          attachment.turnitin = extractDataFor(submission, "attachment_#{attachment.id}", @options.context_url)
      @dialog.html(submissionDetailsDialog(@submission))
      @dialog.find('select').trigger('change')
      @scrollCommentsToBottom()

    @cachedDialogs: {}

    @open: (assignment, student, options) ->
      (SubmissionDetailsDialog.cachedDialogs["#{assignment.id}-#{student.id}"] ||= new SubmissionDetailsDialog(assignment, student, options)).open()

