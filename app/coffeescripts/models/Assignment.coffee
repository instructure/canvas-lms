define [
  'jquery'
  'underscore'
  'Backbone'
  'compiled/backbone-ext/DefaultUrlMixin'
  'compiled/models/TurnitinSettings'
  'compiled/collections/AssignmentOverrideCollection'
], ($, _, {Model}, DefaultUrlMixin, TurnitinSettings, AssignmentOverrideCollection ) ->

  class Assignment extends Model
    @mixin DefaultUrlMixin
    resourceName: 'assignments'

    urlRoot: -> @_defaultUrl()

    defaults:
      "publishable": true

    initialize: ->
      if (overrides = @get('assignment_overrides'))?
        @set 'assignment_overrides', new AssignmentOverrideCollection(overrides)
      if (turnitin_settings = @get('turnitin_settings'))?
        @set 'turnitin_settings', new TurnitinSettings(turnitin_settings),
          silent: true

    isQuiz: => @_hasOnlyType 'online_quiz'
    isDiscussionTopic: => @_hasOnlyType 'discussion_topic'
    isExternalTool: => @_hasOnlyType 'external_tool'
    isNotGraded: => @_hasOnlyType 'not_graded'
    isAssignment: =>
      ! _.include @_submissionTypes(), 'online_quiz', 'discussion_topic',
        'not_graded', 'external_tool'

    assignmentType: (type) =>
      return @_getAssignmentType() unless arguments.length > 0
      if type == 'assignment'
        @set 'submission_types', [ 'none' ]
      else
        @set 'submission_types', [ type ]

    dueAt: (date) =>
      return @get 'due_at' unless arguments.length > 0
      @set 'due_at', date

    unlockAt: (date) =>
      return @get 'unlock_at' unless arguments.length > 0
      @set 'unlock_at', date

    lockAt: (date)  =>
      return @get 'lock_at' unless arguments.length > 0
      @set 'lock_at', date

    description: (newDescription) =>
      return @get 'description' unless arguments.length > 0
      @set 'description', newDescription

    name: (newName) =>
      return @get 'name' unless arguments.length > 0
      @set 'name', newName

    pointsPossible: (points) =>
      return @get('points_possible') || 0 unless arguments.length > 0
      @set 'points_possible', points

    assignmentGroupId: (assignment_group_id) =>
      return @get 'assignment_group_id' unless arguments.length > 0
      @set 'assignment_group_id', assignment_group_id

    canFreeze: =>
      @get('frozen_attributes')? && !@frozen()

    freezeOnCopy: =>
      @get('freeze_on_copy')

    frozen: =>
      @get('frozen')

    frozenAttributes: =>
      @get('frozen_attributes') || []

    gradingType: (gradingType) =>
      return @get('grading_type') || 'points' unless gradingType
      @set 'grading_type', gradingType

    courseID: => @get('course_id')

    submissionTypes: (submissionTypes) =>
      return @_submissionTypes() unless arguments.length > 0
      @set 'submission_types', submissionTypes

    submissionType: =>
      submissionTypes = @_submissionTypes()
      if _.include(submissionTypes, 'none') || submissionTypes.length == 0 then 'none'
      else if _.include submissionTypes, 'on_paper' then 'on_paper'
      else if _.include submissionTypes, 'external_tool' then 'external_tool'
      else 'online'

    acceptsOnlineUpload: =>
      !! _.include @_submissionTypes(), 'online_upload'

    acceptsOnlineURL: =>
      !! _.include @_submissionTypes(), 'online_url'

    acceptsMediaRecording: =>
      !! _.include @_submissionTypes(), 'media_recording'

    acceptsOnlineTextEntries: =>
      !! _.include @_submissionTypes(), 'online_text_entry'

    isOnlineSubmission: =>
      _.any @_submissionTypes(), (thing) ->
          thing in ['online', 'online_text_entry',
            'media_recording', 'online_url', 'online_upload']

    peerReviews: (peerReviewBoolean) =>
      return @get 'peer_reviews' unless arguments.length > 0
      @set 'peer_reviews', peerReviewBoolean

    automaticPeerReviews: (autoPeerReviewBoolean) =>
      return @get 'automatic_peer_reviews' unless arguments.length > 0
      @set 'automatic_peer_reviews', autoPeerReviewBoolean

    peerReviewCount:(peerReviewCount) =>
      return @get('peer_review_count') || 0 unless arguments.length > 0
      @set 'peer_review_count', peerReviewCount

    peerReviewsAssignAt: (date)  =>
      return @get('peer_reviews_assign_at') || null unless arguments.length > 0
      @set 'peer_reviews_assign_at', date

    notifyOfUpdate: (notifyOfUpdateBoolean) =>
      return @get 'notify_of_update' unless arguments.length > 0
      @set 'notify_of_update', notifyOfUpdateBoolean

    restrictFileExtensions: => !!@allowedExtensions()

    allowedExtensions: (extensionsList) =>
      return @get('allowed_extensions') unless arguments.length > 0
      @set 'allowed_extensions', extensionsList

    turnitinAvailable: =>
      typeof @get('turnitin_enabled') != 'undefined'

    gradeGroupStudentsIndividually: (setting) =>
      return @get('grade_group_students_individually') unless arguments.length > 0
      @set 'grade_group_students_individually', setting

    turnitinEnabled: (setting) =>
      if arguments.length == 0
        if @get( 'turnitin_enabled' ) == undefined
          false
        else
          !!@get( 'turnitin_enabled' )
      else
        @set( 'turnitin_enabled', setting )

    groupCategoryId: (id) =>
      return @get( 'group_category_id' ) unless arguments.length > 0
      @set 'group_category_id', id

    gradingStandardId: (id) =>
      return @get('grading_standard_id') unless arguments.length > 0
      @set 'grading_standard_id', id

    externalToolUrl: (url) =>
      tagAttributes = @get('external_tool_tag_attributes') || {}
      return tagAttributes.url unless arguments.length > 0
      tagAttributes.url = url
      @set 'external_tool_tag_attributes', tagAttributes

    externalToolNewTab: (b) =>
      tagAttributes = @get('external_tool_tag_attributes') || {}
      return tagAttributes.new_tab unless arguments.length > 0
      tagAttributes.new_tab = b
      @set 'external_tool_tag_attributes', tagAttributes

    isSimple: =>
      overrides = @get('assignment_overrides')
      @gradingType() == 'points' and
        @submissionType() == 'none' and
        !@groupCategoryId() and
        !@peerReviews() and
        !@frozen() and
        (!overrides or overrides.isSimple())

    isLetterGraded: =>
      @gradingType() == 'letter_grade'

    published: (newPublished) =>
      return @get 'published' unless arguments.length > 0
      @set 'published', newPublished

    iconType: =>
      return 'quiz' if @isQuiz()
      return 'discussion' if @isDiscussionTopic()
      return 'assignment'

    htmlUrl: => @get 'html_url'

    modules: (names)  =>
      return @get 'modules' unless arguments.length > 0
      @set 'modules', names

    labelId: =>
      return @id

    toView: =>
      fields = [
        'name', 'dueAt','description','pointsPossible', 'lockAt', 'unlockAt',
        'gradingType', 'notifyOfUpdate', 'peerReviews', 'automaticPeerReviews',
        'peerReviewCount', 'peerReviewsAssignAt',
        'acceptsOnlineUpload','acceptsMediaRecording', 'submissionType',
        'acceptsOnlineTextEntries', 'acceptsOnlineURL', 'allowedExtensions',
        'restrictFileExtensions', 'isOnlineSubmission', 'isNotGraded',
        'isExternalTool', 'externalToolUrl', 'externalToolNewTab',
        'turnitinAvailable','turnitinEnabled',
        'gradeGroupStudentsIndividually', 'groupCategoryId', 'frozen',
        'frozenAttributes', 'freezeOnCopy', 'canFreeze', 'isSimple',
        'gradingStandardId', 'isLetterGraded', 'assignmentGroupId', 'iconType',
        'published', 'htmlUrl', 'modules', 'labelId'
      ]
      hash = id: @get 'id'
      for field in fields
        hash[field] = @[field]()
      hash

    toJSON: ->
      data = super
      data = @_filterFrozenAttributes(data)
      if @alreadyScoped then data else { assignment: data }

    parse: (data) ->
      data = super data
      if (overrides = data.assignment_overrides)?
        data.assignment_overrides = new AssignmentOverrideCollection overrides
      if (turnitin_settings = data.turnitin_settings)?
        data.turnitin_settings = new TurnitinSettings turnitin_settings
      data

    # Update the Assignment model instance to not parse results from the
    # server. This is a hack to work around the fact that the server will
    # always return an overridden due date after a successful PUT request. If
    # that is parsed and set on the model, and then another save() is called,
    # the assignments default due date will be updated accidentally. Ugh.
    doNotParse: ->
      @parse = -> {}

    # @api private
    _submissionTypes: =>
      @get('submission_types') || []

    # @api private
    _hasOnlyType: (type) =>
      submissionTypes = @_submissionTypes()
      submissionTypes.length == 1 && submissionTypes[0] == type

    # @api private
    _getAssignmentType: =>
      if @isDiscussionTopic() then 'discussion_topic'
      else if @isQuiz() then 'online_quiz'
      else if @isExternalTool() then 'external_tool'
      else if @isNotGraded() then 'not_graded'
      else 'assignment'

    _filterFrozenAttributes: (data) =>
      for own key, value of @attributes
        if _.contains(@frozenAttributes(), key)
          delete data[key]
      if _.contains(@frozenAttributes(), "title")
        delete data.name
      if _.contains(@frozenAttributes(), "group_category_id")
        delete data.grade_group_students_individually
      if _.contains(@frozenAttributes(), "peer_reviews")
        delete data.automatic_peer_reviews
        delete data.peer_review_count
        delete data.peer_reviews_assign_at
      delete data.frozen
      delete data.frozen_attributes
      data

    setNullDates: =>
      @dueAt null
      @lockAt null
      @unlockAt null
      this

    publish: -> @save("published", true)
    unpublish: -> @save("published", false)
