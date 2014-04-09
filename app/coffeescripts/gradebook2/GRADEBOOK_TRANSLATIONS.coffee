define ['i18n!gradebook2'], (I18n) ->
 GRADEBOOK_TRANSLATIONS =
    submission_tooltip_dropped: I18n.t('dropped_for_grading', 'Dropped for grading purposes'),
    submission_tooltip_late: I18n.t('submitted_late', 'Submitted late'),
    submission_tooltip_muted: I18n.t('assignment_muted', 'Assignment muted'),
    submission_tooltip_resubmitted: I18n.t('resubmitted', 'Resubmitted since last graded'),
    submission_tooltip_ungraded: I18n.t('ungraded', 'Not factored into grading'),
    submission_tooltip_online_url: I18n.t('titles.url', "URL Submission"),
    submission_tooltip_discussion_topic: I18n.t('titles.discussion', "Discussion Submission"),
    submission_tooltip_online_upload: I18n.t('titles.upload', "File Upload Submission"),
    submission_tooltip_online_text_entry: I18n.t('titles.text', "Text Entry Submission"),
    submission_tooltip_pending_review: I18n.t('titles.quiz_review', "This quiz needs review"),
    submission_tooltip_media_comment: I18n.t('titles.media', "Media Comment Submission"),
    submission_tooltip_media_recording: I18n.t('titles.media_recording', "Media Recording Submission"),
    submission_tooltip_online_quiz: I18n.t('title.quiz', "Quiz Submission"),
    submission_tooltip_turnitin: I18n.t('title.turnitin', 'Has Turnitin score'),
    submission_update_error: I18n.t('error.update', 'There was an error updating this assignment. Please refresh the page and try again.')
