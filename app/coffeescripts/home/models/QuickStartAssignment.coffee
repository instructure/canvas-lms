define ['Backbone'], ({Model}) ->

  class QuickStartAssignment extends Model

    defaults:
      title: 'No Title'
      description: 'No Description'
      due_at: null
      points_possible: null
      grading_type: 'points'
      submission_types: 'online_upload,online_text_entry'

