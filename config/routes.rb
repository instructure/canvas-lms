ActionController::Routing::Routes.draw do |map|

  map.resources :submission_comments, :only => :destroy

  map.mark_inbox_as_read 'inbox', :controller => 'context', :action => 'mark_inbox_as_read', :conditions => {:method => :delete}
  map.inbox 'inbox', :controller => 'context', :action => 'inbox'
  map.destroy_inbox_item 'inbox/:id', :controller => 'context', :action => 'destroy_inbox_item', :conditions => {:method => :delete}
  map.inbox_item 'inbox/:id', :controller => 'context', :action => 'inbox_item'

  map.discussion_replies 'conversations/discussion_replies', :controller => 'context', :action => 'discussion_replies'
  map.conversations_unread 'conversations/unread', :controller => 'conversations', :action => 'index', :redirect_scope => 'unread'
  map.conversations_starred 'conversations/starred', :controller => 'conversations', :action => 'index', :redirect_scope => 'starred'
  map.conversations_sent 'conversations/sent', :controller => 'conversations', :action => 'index', :redirect_scope => 'sent'
  map.conversations_archived 'conversations/archived', :controller => 'conversations', :action => 'index', :redirect_scope => 'archived'
  map.connect 'conversations/find_recipients', :controller => 'search', :action => 'recipients' # use search_recipients_url instead
  map.search_recipients 'search/recipients', :controller => 'search', :action => 'recipients'
  map.conversations_mark_all_as_read 'conversations/mark_all_as_read', :controller => 'conversations', :action => 'mark_all_as_read', :conditions => {:method => :post}
  map.conversations_watched_intro 'conversations/watched_intro', :controller => 'conversations', :action => 'watched_intro', :conditions => {:method => :post}
  map.conversation_batches 'conversations/batches', :controller => 'conversations', :action => 'batches'
  map.resources :conversations, :only => [:index, :show, :update, :create, :destroy] do |conversation|
    conversation.add_recipients 'add_recipients', :controller => 'conversations', :action => 'add_recipients', :conditions => {:method => :post}
    conversation.add_message 'add_message', :controller => 'conversations', :action => 'add_message', :conditions => {:method => :post}
    conversation.remove_messages 'remove_messages', :controller => 'conversations', :action => 'remove_messages', :conditions => {:method => :post}
  end

  # So, this will look like:
  # http://instructure.com/register/5R32s9iqwLK75Jbbj0
  map.registration_confirmation 'register/:nonce',
    :controller => 'communication_channels', :action => 'confirm'
  # deprecated
  map.registration_confirmation_deprecated 'pseudonyms/:id/register/:nonce',
    :controller => 'communication_channels', :action => 'confirm'
  map.re_send_confirmation 'confirmations/:user_id/re_send/:id',
    :controller => 'communication_channels', :action => 're_send_confirmation', :id => nil
  map.forgot_password "forgot_password",
    :controller => 'pseudonyms', :action => 'forgot_password'
  map.confirm_change_password "pseudonyms/:pseudonym_id/change_password/:nonce",
    :controller => 'pseudonyms', :action => 'confirm_change_password', :conditions => {:method => :get}
  map.change_password "pseudonyms/:pseudonym_id/change_password/:nonce",
    :controller => 'pseudonyms', :action => 'change_password', :conditions => {:method => :post}

  # callback urls for oauth authorization processes
  map.oauth "oauth", :controller => "users", :action => "oauth"
  map.oauth_success "oauth_success", :controller => "users", :action => "oauth_success"

  map.message_redirect "mr/:id", :controller => 'info', :action => 'message_redirect'
  map.help_links 'help_links', :controller => 'info', :action => 'help_links'


  def add_question_banks(context)
    context.resources :question_banks do |bank|
      bank.bookmark 'bookmark', :controller => 'question_banks', :action => 'bookmark'
      bank.reorder 'reorder', :controller => 'question_banks', :action => 'reorder'
      bank.questions 'questions', :controller => 'question_banks', :action => 'questions'
      bank.move_questions 'move_questions', :controller => 'question_banks', :action => 'move_questions'
      bank.resources :assessment_questions do |question|
        question.move_question 'move', :controller => 'assessment_questions', :action => 'move'
      end
    end
  end

  def add_groups(context)
    context.resources :groups
    context.resources :group_categories, :only => [:create, :update, :destroy]
    context.group_unassigned_members 'group_unassigned_members', :controller => 'groups', :action => 'unassigned_members', :conditions => { :method => :get }
    context.group_unassigned_members 'group_unassigned_members.:format', :controller => 'groups', :action => 'unassigned_members', :conditions => { :method => :get }
    context.group_assign_unassigned_members 'group_assign_unassigned_members', :controller => 'groups', :action => 'assign_unassigned_members', :conditions => { :method => :post }
  end

  def add_files(context, options={})
    context.resources :files, :collection => {:quota => :get, :reorder => :post} do |file|
      file.text_inline 'inline', :controller => 'files', :action => 'text_show'
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
      file.typed_download 'download.:type', :controller => 'files', :action => 'show', :download => '1'
      file.preview 'preview', :controller => 'files', :action => 'show', :preview => '1'
      file.inline_view 'inline_view', :controller => 'files', :action => 'show', :inline => '1'
      file.attachment_content 'contents', :controller => 'files', :action => 'attachment_content'
      file.relative_path ":file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    end
    context.images 'images', :controller => 'files', :action => 'images' if options[:images]
    context.relative_file_path "file_contents/:file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative' if options[:relative]
    if options[:folders]
      context.resources :folders do |folder|
        folder.download 'download', :controller => 'folders', :action => 'download'
      end
    end
  end

  def add_media(context)
    context.media_download 'media_download', :controller => 'users', :action => 'media_download'
    context.typed_media_download 'media_download.:type', :controller => 'users', :action => 'media_download'
  end

  def add_users(context)
    context.users 'users', :controller => 'context', :action => 'roster'
    context.user_services 'user_services', :controller => 'context', :action => 'roster_user_services'
    context.user_usage 'users/:user_id/usage', :controller => 'context', :action => 'roster_user_usage'
    yield if block_given?
    context.user 'users/:id', :controller => 'context', :action => 'roster_user', :conditions => {:method => :get}
  end

  def add_chat(context)
    context.resources :chats
    context.chat 'chat', :controller => 'context', :action => 'chat'
    context.tinychat 'tinychat.html', :controller => 'context', :action => 'chat_iframe'
    context.formatted_chat 'chat.:format', :controller => 'context', :action => 'chat'
  end

  def add_announcements(context)
    context.resources :announcements
    context.announcements_external_feeds "announcements/external_feeds", :controller => 'announcements', :action => 'create_external_feed', :conditions => { :method => :post }
    context.announcements_external_feed "announcements/external_feeds/:id", :controller => 'announcements', :action => 'destroy_external_feed', :conditions => { :method => :delete }
  end

  def add_discussions(context)
    context.resources :discussion_topics, :only => [:index, :new, :show, :edit, :destroy]
    context.map 'discussion_topics/:id/:extras', :extras => /.+/, :controller => :discussion_topics, :action => :show
    context.resources :discussion_entries
  end

  def add_wiki(context)
    context.resources :wiki_pages, :as => 'wiki' do |wiki_page|
      wiki_page.latest_version_number 'revisions/latest', :controller => 'wiki_page_revisions', :action => 'latest_version_number'
      wiki_page.resources :wiki_page_revisions, :as => "revisions"
      wiki_page.resources :wiki_page_comments, :as => "comments"
    end
    context.named_wiki_page 'wiki/:id', :id => /[^\/]+/, :controller => 'wiki_pages', :action => 'show'
  end

  def add_conferences(context)
    context.resources :conferences do |conference|
      conference.join "join", :controller => "conferences", :action => "join"
      conference.close "close", :controller => "conferences", :action => "close"
      conference.settings "settings", :controller => "conferences", :action => "settings"
    end
  end

  def add_zip_file_imports(context)
    context.resources :zip_file_imports, :only => [:new, :create, :show]
    context.import_files 'imports/files', :controller => 'content_imports', :action => 'files'
  end

  # There are a lot of resources that are all scoped to the course level
  # (assignments, files, wiki pages, user lists, forums, etc.).  Many of
  # these resources also apply to groups and individual users.  We call
  # courses, users, groups, or even accounts in this setting, "contexts".
  # There are some helper methods like the before_filter :get_context in application_controller
  # and the application_helper method :context_url to make retrieving
  # these contexts, and also generating context-specific urls, easier.
  map.resources :courses do |course|
    # DEPRECATED
    course.self_enrollment 'self_enrollment/:self_enrollment', :controller => 'courses', :action => 'self_enrollment', :conditions => {:method => :get}
    course.self_unenrollment 'self_unenrollment/:self_unenrollment', :controller => 'courses', :action => 'self_unenrollment', :conditions => {:method => :post}
    course.restore 'restore', :controller => 'courses', :action => 'restore'
    course.backup 'backup', :controller => 'courses', :action => 'backup'
    course.unconclude 'unconclude', :controller => 'courses', :action => 'unconclude'
    course.students 'students', :controller => 'courses', :action => 'students'
    course.enrollment_invitation 'enrollment_invitation', :controller => 'courses', :action => 'enrollment_invitation'
    add_users(course) do
      course.prior_users 'users/prior', :controller => 'context', :action => 'prior_users'
    end
    course.statistics 'statistics', :controller => 'courses', :action => 'statistics'
    course.unenroll 'unenroll/:id', :controller => 'courses', :action => 'unenroll_user', :conditions => {:method => :delete}
    course.move_enrollment 'move_enrollment/:id', :controller => 'courses', :action => 'move_enrollment', :conditions => {:method => :post}
    course.formatted_unenroll 'unenroll/:id.:format', :controller => 'courses', :action => 'unenroll_user', :conditions => {:method => :delete}
    course.limit_user_grading 'limit_user_grading/:id', :controller => 'courses', :action => 'limit_user', :conditions => {:method => :post}
    course.conclude_user_enrollment 'conclude_user/:id', :controller => 'courses', :action => 'conclude_user', :conditions => {:method => :delete}
    course.unconclude_user_enrollment 'unconclude_user/:id', :controller => 'courses', :action => 'unconclude_user', :conditions => {:method => :post}
    course.resources :sections, :except => %w(index edit new) do |section|
      section.confirm_crosslist 'crosslist/confirm/:new_course_id', :controller => 'sections', :action => 'crosslist_check'
      section.crosslist 'crosslist', :controller => 'sections', :action => 'crosslist', :conditions => {:method => :post}
      section.uncrosslist 'crosslist', :controller => 'sections', :action => 'uncrosslist', :conditions => {:method => :delete}
    end
    course.undelete_items 'undelete', :controller => 'context', :action => 'undelete_index'
    course.undelete_item 'undelete/:asset_string', :controller => 'context', :action => 'undelete_item'
    course.settings 'settings', :controller => 'courses', :action => 'settings'
    course.details 'details', :controller => 'courses', :action => 'settings'
    course.re_send_invitations 're_send_invitations', :controller => 'courses', :action => 're_send_invitations', :conditions => {:method => :post}
    course.enroll_users 'enroll_users', :controller => 'courses', :action => 'enroll_users'
    course.link_enrollment 'link_enrollment', :controller => 'courses', :action => 'link_enrollment'
    course.update_nav 'update_nav', :controller => 'courses', :action => 'update_nav'
    course.formatted_enroll_users 'enroll_users.:format', :controller => 'courses', :action => 'enroll_users'
    course.resource :gradebook, :collection => {
      :change_gradebook_version => :get,
      :blank_submission => :get,
      :speed_grader => :get,
      :update_submission => :post,
      :history => :get
    } do |gradebook|
      gradebook.submissions_upload 'submissions_upload/:assignment_id', :controller => 'gradebooks', :action => 'submissions_zip_upload', :conditions => { :method => :post }
    end
    course.resource :gradebook2,
      :controller => 'gradebook2'
    course.attendance 'attendance', :controller => 'gradebooks', :action => 'attendance'
    course.attendance_user 'attendance/:user_id', :controller => 'gradebooks', :action => 'attendance'
    course.imports 'imports', :controller => 'content_imports', :action => 'intro'
    add_zip_file_imports(course)
    course.import_quizzes 'imports/quizzes', :controller => 'content_imports', :action => 'quizzes'
    course.import_content 'imports/content', :controller => 'content_imports', :action => 'content'
    course.import_choose_course 'imports/choose_course', :controller => 'content_imports', :action => 'choose_course', :conditions => {:method => :get}
    course.import_choose_content 'imports/choose_content', :controller => 'content_imports', :action => 'choose_content', :conditions => {:method => :get}
    course.import_copy_course_checklist 'imports/copy_course_checklist', :controller => 'content_imports', :action => 'copy_course_checklist', :conditions => {:method => :get}
    course.import_copy_course_finish 'imports/copy_course_finish', :controller => 'content_imports', :action => 'copy_course_finish', :conditions => {:method => :get}
    course.import_migrate 'imports/migrate', :controller => 'content_imports', :action => 'migrate_content'
    course.import_upload 'imports/upload', :controller => 'content_imports', :action => 'migrate_content_upload'
    course.import_s3_success 'imports/s3_success', :controller => 'content_imports', :action => 'migrate_content_s3_success'
    course.import_copy_content 'imports/copy', :controller => 'content_imports', :action => 'copy_course_content', :conditions => {:method => :post}
    course.import_migrate_choose 'imports/migrate/:id', :controller => 'content_imports', :action => 'migrate_content_choose'
    course.import_migrate_execute 'imports/migrate/:id/execute', :controller => 'content_imports', :action => 'migrate_content_execute'
    course.import_review 'imports/review', :controller => 'content_imports', :action => 'review'
    course.import_list 'imports/list', :controller => 'content_imports', :action => 'index'
    course.import_copy_status 'imports/:id', :controller => 'content_imports', :action => 'copy_course_status', :conditions => {:method => :get}
    course.download_import_archive 'imports/:id/download_archive', :controller => 'content_imports', :action => 'download_archive', :conditions => {:method => :get}
    course.resource :gradebook_upload
    course.grades "grades", :controller => 'gradebooks', :action => 'grade_summary', :id => nil
    course.grading_rubrics "grading_rubrics", :controller => 'gradebooks', :action => 'grading_rubrics'
    course.student_grades "grades/:id", :controller => 'gradebooks', :action => 'grade_summary'
    add_announcements(course)
    add_chat(course)
    course.old_calendar 'calendar', :controller => 'calendars', :action => 'show'
    course.locks 'locks', :controller => 'courses', :action => 'locks'
    add_discussions(course)
    course.resources :assignments, :collection => {:syllabus => :get, :submissions => :get}, :member => {:list_google_docs => :get, :update_submission => :any} do |assignment|
      assignment.resources :submissions do |submission|
        submission.resubmit_to_turnitin 'turnitin/resubmit', :controller => 'submissions', :action => 'resubmit_to_turnitin', :conditions => {:method => :post}
        submission.turnitin_report 'turnitin/:asset_string', :controller => 'submissions', :action => 'turnitin_report'
      end
      assignment.rubric "rubric", :controller => 'assignments', :action => 'rubric'
      assignment.resource :rubric_association, :as => :rubric do |association|
        association.resources :rubric_assessments, :as => 'assessments'
      end
      assignment.peer_reviews "peer_reviews", :controller => 'assignments', :action => 'peer_reviews', :conditions => {:method => :get}
      assignment.assign_peer_reviews "assign_peer_reviews", :controller => 'assignments', :action => 'assign_peer_reviews', :conditions => {:method => :post}
      assignment.delete_peer_review "peer_reviews/:id", :controller => 'assignments', :action => 'delete_peer_review', :conditions => {:method => :delete}
      assignment.remind_peer_review "peer_reviews/:id", :controller => 'assignments', :action => 'remind_peer_review', :conditions => {:method => :post}
      assignment.assign_peer_review "peer_reviews/users/:reviewer_id", :controller => 'assignments', :action => 'assign_peer_review', :conditions => {:method => :post}
      assignment.mute "mute", :controller => "assignments", :action => "toggle_mute", :conditions => {:method => :put}
    end
    course.resources :grading_standards, :only => %w(index create update destroy)
    course.resources :assignment_groups, :collection => {:reorder => :post} do |group|
      group.reorder_assignments 'reorder', :controller => 'assignment_groups', :action => 'reorder_assignments'
    end
    course.resources :external_tools, :collection => {:retrieve => :get, :homework_submissions => :get} do |tools|
      tools.resource_selection 'resource_selection', :controller => 'external_tools', :action => 'resource_selection'
      tools.homework_submission 'homework_submission', :controller => 'external_tools', :action => 'homework_submission'
      tools.finished 'finished', :controller => 'external_tools', :action => 'finished'
    end
    course.resources :submissions
    course.resources :calendar_events
    add_files(course, :relative => true, :images => true, :folders => true)
    add_groups(course)
    add_wiki(course)
    add_conferences(course)
    add_question_banks(course)
    course.quizzes_publish 'quizzes/publish', :controller => 'quizzes', :action => 'publish'
    course.resources :quizzes do |quiz|
      quiz.managed_quiz_data "managed_quiz_data", :controller => "quizzes", :action => "managed_quiz_data"
      quiz.reorder "reorder", :controller => "quizzes", :action => "reorder"
      quiz.history "history", :controller => "quizzes", :action => "history"
      quiz.statistics "statistics", :controller => 'quizzes', :action => 'statistics'
      quiz.read_only "read_only", :controller => 'quizzes', :action => 'read_only'
      quiz.filters 'filters', :controller => 'quizzes', :action => 'filters'

      quiz.resources :quiz_submissions, :as => "submissions", :collection => {:backup => :put, :index => :get}, :member => {:record_answer => :post} do |submission|
      end
      quiz.extensions 'extensions/:user_id', :controller => 'quiz_submissions', :action => 'extensions', :conditions => {:method => :post}
      quiz.resources :quiz_questions, :as => "questions", :only => %w(create update destroy show)
      quiz.resources :quiz_groups, :as => "groups", :only => %w(create update destroy) do |group|
        group.reorder "reorder", :controller => "quiz_groups", :action => "reorder"
      end

      quiz.with_options :controller => "quizzes", :action => "show", :take => '1' do |take_quiz|
        take_quiz.take "take"
        take_quiz.question "take/questions/:question_id"
      end

      quiz.moderate "moderate", :controller => "quizzes", :action => "moderate"
      quiz.lockdown_browser_required "lockdown_browser_required", :controller => "quizzes", :action => "lockdown_browser_required"
    end
    map.quiz_statistics_download 'quiz_statistics/:quiz_statistics_id/files/:file_id/download',
      :controller => 'files', :action => 'show', :download => '1'

    course.resources :collaborations

    course.resources :gradebook_uploads
    course.resources :rubrics
    course.resources :rubric_associations do |association|
      association.invite_assessor "invite", :controller => "rubric_assessments", :action => "invite"
      association.remind_assessee "remind/:assessment_request_id", :controller => "rubric_assessments", :action => "remind"
      association.resources :rubric_assessments, :as => 'assessments'
    end
    course.user_outcomes_results 'outcomes/users/:user_id', :controller => 'outcomes', :action => 'user_outcome_results'
    course.resources :outcomes, :collection => {:list => :get, :add_outcome => :post} do |outcome|
      outcome.reorder_alignments 'alignments/reorder', :controller => 'outcomes', :action => 'reorder_alignments', :conditions => {:method => :post}
      outcome.alignment_redirect 'alignments/:id', :controller => 'outcomes', :action => 'alignment_redirect', :conditions => {:method => :get}
      outcome.align 'alignments', :controller => 'outcomes', :action => 'align', :conditions => {:method => :post}
      outcome.remove_alignment 'alignments/:id', :controller => 'outcomes', :action => 'remove_alignment', :conditions => {:method => :delete}
      outcome.results 'results', :controller => 'outcomes', :action => 'outcome_results'
      outcome.result 'results/:id', :controller => 'outcomes', :action => 'outcome_result'
      outcome.details 'details', :controller => 'outcomes', :action => 'details'
    end
    course.resources :outcome_groups, :only => %w(create update destroy) do |group|
      group.reorder 'reorder', :controller => 'outcome_groups', :action => 'reorder'
    end
    course.resources :context_modules, :as => :modules, :collection => {:reorder => :post, :progressions => :get} do |m|
      m.add_item 'items', :controller => 'context_modules', :action => 'add_item', :conditions => {:method => :post}
      m.reorder 'reorder', :controller => 'context_modules', :action => 'reorder_items', :conditions => {:method => :post}
      m.toggle_collapse 'collapse', :controller => 'context_modules', :action => 'toggle_collapse'
      m.prerequisites_needing_finishing 'prerequisites/:code', :controller => 'context_modules', :action => 'content_tag_prerequisites_needing_finishing'
      m.last_redirect 'items/last', :controller => 'context_modules', :action => 'module_redirect', :last => 1
      m.first_redirect 'items/first', :controller => 'context_modules', :action => 'module_redirect', :first => 1
    end
    course.resources :content_exports, :only => %w(create index destroy show)
    course.context_modules_assignment_info 'modules/items/assignment_info', :controller => 'context_modules', :action => 'content_tag_assignment_data', :conditions => {:method => :get}
    course.context_modules_item_redirect 'modules/items/:id', :controller => 'context_modules', :action => 'item_redirect', :conditions => {:method => :get}
    course.context_modules_item_details 'modules/items/sequence/:id', :controller => 'context_modules', :action => 'item_details', :conditions => {:method => :get}
    course.context_modules_remove_item 'modules/items/:id', :controller => 'context_modules', :action => 'remove_item', :conditions => {:method => :delete}
    course.context_modules_update_item 'modules/items/:id', :controller => 'context_modules', :action => 'update_item', :conditions => {:method => :put}
    course.confirm_action 'confirm_action', :controller => 'courses', :action => 'confirm_action'
    course.start_copy 'copy', :controller => 'courses', :action => 'copy', :conditions => {:method => :get}
    course.copy_course 'copy', :controller => 'courses', :action => 'copy_course', :conditions => {:method => :post}
    add_media(course)
    course.user_notes 'user_notes', :controller => 'user_notes', :action => 'user_notes'
    course.switch_role 'switch_role/:role', :controller => 'courses', :action => 'switch_role'
    course.sis_publish_status 'details/sis_publish', :controller => 'courses', :action => 'sis_publish_status', :conditions => {:method => :get}
    course.publish_to_sis 'details/sis_publish', :controller => 'courses', :action => 'publish_to_sis', :conditions => {:method => :post}

    course.resources :user_lists, :only => :create
    course.reset 'reset', :controller => 'courses', :action => 'reset_content', :conditions => {:method => :post}
    course.resources :alerts
    course.student_view 'student_view', :controller => 'courses', :action => 'student_view', :conditions => {:method => :post}
    course.student_view 'student_view', :controller => 'courses', :action => 'leave_student_view', :conditions => {:method => :delete}
    course.test_student 'test_student', :controller => 'courses', :action => 'reset_test_student', :conditions => {:method => :delete}
  end

  map.connect '/submissions/:submission_id/attachments/:attachment_id/crocodoc_sessions',
    :controller => :crocodoc_sessions, :action => :create,
    :conditions => {:method => :post}
  map.connect '/attachments/:attachment_id/crocodoc_sessions',
    :controller => :crocodoc_sessions, :action => :create,
    :conditions => {:method => :post}

  map.resources :page_views, :only => [:update]
  map.create_media_object 'media_objects', :controller => 'context', :action => 'create_media_object', :conditions => {:method => :post}
  map.kaltura_notifications 'media_objects/kaltura_notifications', :controller => 'context', :action => 'kaltura_notifications'
  map.media_object 'media_objects/:id', :controller => 'context', :action => 'media_object_inline'
  map.media_object_redirect 'media_objects/:id/redirect', :controller => 'context', :action => 'media_object_redirect'
  map.media_object_thumbnail 'media_objects/:id/thumbnail', :controller => 'context', :action => 'media_object_thumbnail'
  map.media_object_info 'media_objects/:media_object_id/info', :controller => 'media_objects', :action => 'show'

  map.show_media_tracks "media_objects/:media_object_id/media_tracks/:id", :controller => :media_tracks, :action => :show, :conditions => {:method => :get}
  map.create_media_tracks 'media_objects/:media_object_id/media_tracks', :controller => :media_tracks, :action => :create, :conditions => {:method => :post}
  map.delete_media_tracks "media_objects/:media_object_id/media_tracks/:media_track_id", :controller => :media_tracks, :action => :destroy, :conditions => {:method => :delete}

  map.external_content_success 'external_content/success/:service', :controller => 'external_content', :action => 'success'
  map.external_content_oembed_retrieve 'external_content/retrieve/oembed', :controller => 'external_content', :action => 'oembed_retrieve'
  map.external_content_cancel 'external_content/cancel/:service', :controller => 'external_content', :action => 'cancel'

  # We offer a bunch of atom and ical feeds for the user to get
  # data out of Instructure.  The :feed_code attribute is keyed
  # off of either a user, and enrollment, a course, etc. based on
  # that item's uuid.  In config/initializers/active_record.rb you'll
  # find a feed_code method to generate the code, and in
  # application_controller there's a get_feed_context to get it back out.
  map.resource :feeds do |feed|
    feed.calendar "calendars/:feed_code", :controller => "calendar_events_api", :action => "public_feed"
    feed.calendar_format "calendars/:feed_code.:format", :controller => "calendar_events_api", :action => "public_feed"
    feed.forum "forums/:feed_code", :controller => "discussion_topics", :action => "public_feed"
    feed.forum_format "forums/:feed_code.:format", :controller => "discussion_topics", :action => "public_feed"
    feed.topic "topics/:discussion_topic_id/:feed_code", :controller => "discussion_entries", :action => "public_feed"
    feed.topic_format "topics/:discussion_topic_id/:feed_code.:format", :controller => "discussion_entries", :action => "public_feed"
    feed.announcements "announcements/:feed_code", :controller => "announcements", :action => "public_feed"
    feed.announcements_format "announcements/:feed_code.:format", :controller => "announcements", :action => "public_feed"
    feed.course "courses/:feed_code", :controller => "courses", :action => "public_feed"
    feed.course_format "courses/:feed_code.:format", :controller => "courses", :action => "public_feed"
    feed.group "groups/:feed_code", :controller => "groups", :action => "public_feed"
    feed.group_format "groups/:feed_code.:format", :controller => "groups", :action => "public_feed"
    feed.enrollment "enrollments/:feed_code", :controller => "courses", :action => "public_feed"
    feed.enrollment_format "enrollments/:feed_code.:format", :controller => "courses", :action => "public_feed"
    feed.user "users/:feed_code", :controller => "users", :action => "public_feed"
    feed.user_format "users/:feed_code.:format", :controller => "users", :action => "public_feed"
    feed.eportfolio "eportfolios/:eportfolio_id.:format", :controller => "eportfolios", :action => "public_feed"
    feed.conversation "conversations/:feed_code", :controller => "conversations", :action => "public_feed"
    feed.conversation_format "conversations/:feed_code.:format", :controller => "conversations", :action => "public_feed"
  end

  map.resources :assessment_questions do |question|
    question.map 'files/:id/download', :controller => 'files', :action => 'assessment_question_show', :download => '1'
    question.map 'files/:id/preview', :controller => 'files', :action => 'assessment_question_show', :preview => '1'
    question.verified_file 'files/:id/:verifier', :controller => 'files', :action => 'assessment_question_show', :download => '1'
  end

  map.resources :eportfolios, :except => [:index]  do |eportfolio|
    eportfolio.reorder_categories "reorder_categories", :controller => "eportfolios", :action => "reorder_categories"
    eportfolio.reorder_entries ":eportfolio_category_id/reorder_entries", :controller => "eportfolios", :action => "reorder_entries"
    eportfolio.resources :categories, :controller => "eportfolio_categories"
    eportfolio.resources :entries, :controller => "eportfolio_entries" do |entry|
      entry.resources :page_comments, :as => "comments", :only => %w(create destroy)
      entry.view_file "files/:attachment_id", :conditions => {:method => :get}, :controller => "eportfolio_entries", :action => "attachment"
      entry.preview_submission "submissions/:submission_id", :conditions => {:method => :get}, :controller => "eportfolio_entries", :action => "submission"
    end
    eportfolio.export_portfolio "export", :controller => "eportfolios", :action => "export"
    eportfolio.formatted_export_portfolio "export.:format", :controller => "eportfolios", :action => "export"
    eportfolio.named_category ":category_name", :controller => "eportfolio_categories", :action => "show", :conditions => {:method => :get}
    eportfolio.named_category_entry ":category_name/:entry_name", :controller => "eportfolio_entries", :action => "show", :conditions => {:method => :get}
  end

  map.resources :groups do |group|
    add_users(group)
    group.remove_user 'remove_user/:id', :controller => 'groups', :action => 'remove_user', :conditions => {:method => :delete}
    group.add_user 'add_user', :controller => 'groups', :action => 'add_user'
    group.accept_invitation 'accept_invitation/:uuid', :controller => 'groups', :action => 'accept_invitation', :conditions => {:method => :get}
    group.members 'members.:format', :controller => 'groups', :action => 'context_group_members', :conditions => {:method => :get}
    group.members 'members', :controller => 'groups', :action => 'context_group_members', :conditions => {:method => :get}
    add_announcements(group)
    add_discussions(group)
    group.resources :calendar_events
    add_chat(group)
    add_files(group, :images => true, :folders => true)
    add_zip_file_imports(group)
    group.resources :external_tools, :only => [:show], :collection => {:retrieve => :get}
    add_wiki(group)
    add_conferences(group)
    add_media(group)
    group.resources :collaborations
    group.old_calendar 'calendar', :controller => 'calendars', :action => 'show'
  end

  map.resources :accounts, :member => { :statistics => :get } do |account|
    account.settings 'settings', :controller => 'accounts', :action => 'settings'
    account.admin_tools 'admin_tools', :controller => 'accounts', :action => 'admin_tools'
    account.add_account_user 'account_users', :controller => 'accounts', :action => 'add_account_user', :conditions => {:method => :post}
    account.remove_account_user 'account_users/:id', :controller => 'accounts', :action => 'remove_account_user', :conditions => {:method => :delete}

    account.resources :grading_standards, :only => %w(index create update destroy)

    account.statistics 'statistics', :controller => 'accounts', :action => 'statistics'
    account.statistics_graph 'statistics/over_time/:attribute', :controller => 'accounts', :action => 'statistics_graph'
    account.formatted_statistics_graph 'statistics/over_time/:attribute.:format', :controller => 'accounts', :action => 'statistics_graph'
    account.turnitin_confirmation 'turnitin/:id/:shared_secret', :controller => 'accounts', :action => 'turnitin_confirmation'
    account.resources :permissions, :controller => 'role_overrides', :only => [:index, :create], :collection => {:add_role => :post, :remove_role => :delete}
    account.resources :role_overrides, :only => [:index, :create], :collection => {:add_role => :post, :remove_role => :delete}
    account.resources :terms
    account.resources :sub_accounts
    account.avatars 'avatars', :controller => 'accounts', :action => 'avatars'
    account.sis_import 'sis_import', :controller => 'accounts', :action => 'sis_import', :conditions => { :method => :get }
    account.resources :sis_imports, :controller => 'sis_imports_api', :only => [:create, :show]
    account.add_user 'users', :controller => 'users', :action => 'create', :conditions => {:method => :post}
    account.confirm_delete_user 'users/:user_id/delete', :controller => 'accounts', :action => 'confirm_delete_user'
    account.delete_user 'users/:user_id', :controller => 'accounts', :action => 'remove_user', :conditions => {:method => :delete}
    account.resources :users
    account.resources :account_notifications, :only => [:create, :destroy]
    add_announcements(account)
    account.resources :assignments
    account.resources :submissions
    account.resources :account_authorization_configs
    account.update_all_authorization_configs 'account_authorization_configs', :controller => 'account_authorization_configs', :action => 'update_all', :conditions => {:method => :put}
    account.remove_all_authorization_configs 'account_authorization_configs', :controller => 'account_authorization_configs', :action => 'destroy_all', :conditions => {:method => :delete}
    account.test_ldap_connections 'test_ldap_connections', :controller => 'account_authorization_configs', :action => 'test_ldap_connection'
    account.test_ldap_binds 'test_ldap_binds', :controller => 'account_authorization_configs', :action => 'test_ldap_bind'
    account.test_ldap_searches 'test_ldap_searches', :controller => 'account_authorization_configs', :action => 'test_ldap_search'
    account.test_ldap_logins 'test_ldap_logins', :controller => 'account_authorization_configs', :action => 'test_ldap_login'
    account.saml_testing 'saml_testing', :controller => 'account_authorization_configs', :action => 'saml_testing'
    account.saml_testing_stop 'saml_testing_stop', :controller => 'account_authorization_configs', :action => 'saml_testing_stop'
    account.resources :external_tools do |tools|
      tools.finished 'finished', :controller => 'external_tools', :action => 'finished'
    end
    add_chat(account)
    account.user_outcomes_results 'outcomes/users/:user_id', :controller => 'outcomes', :action => 'user_outcome_results'
    account.resources :outcomes, :collection => {:list => :get, :add_outcome => :post} do |outcome|
      outcome.results 'results', :controller => 'outcomes', :action => 'outcome_results'
      outcome.result 'results/:id', :controller => 'outcomes', :action => 'outcome_result'
      outcome.details 'details', :controller => 'outcomes', :action => 'details'
    end
    account.resources :outcome_groups, :only => %w(create update destroy) do |group|
      group.reorder 'reorder', :controller => 'outcome_groups', :action => 'reorder'
    end
    account.resources :rubrics
    account.resources :rubric_associations do |association|
      association.resources :rubric_assessments, :as => 'assessments'
    end
    add_files(account, :relative => true, :images => true, :folders => true)
    add_media(account)
    add_groups(account)
    account.resources :outcomes
    account.courses 'courses', :controller => 'accounts', :action => 'courses'
    account.courses_formatted 'courses.:format', :controller => 'accounts', :action => 'courses'
    account.courses_redirect 'courses/:id', :controller => 'accounts', :action => 'courses_redirect'
    account.user_notes 'user_notes', :controller => 'user_notes', :action => 'user_notes'
    account.run_report 'run_report', :controller => 'accounts', :action => 'run_report'
    account.resources :alerts
    add_question_banks(account)
    account.resources :user_lists, :only => :create
  end
  map.avatar_image 'images/users/:user_id', :controller => 'users', :action => 'avatar_image', :conditions => {:method => :get}
  map.thumbnail_image 'images/thumbnails/:id/:uuid', :controller => 'files', :action => 'image_thumbnail'
  map.show_thumbnail_image 'images/thumbnails/show/:id/:uuid', :controller => 'files', :action => 'show_thumbnail'
  map.report_avatar_image 'images/users/:user_id/report', :controller => 'users', :action => 'report_avatar_image', :conditions => {:method => :post}
  map.update_avatar_image 'images/users/:user_id', :controller => 'users', :action => 'update_avatar_image', :conditions => {:method => :put}

  map.all_menu_courses 'all_menu_courses', :controller => 'users', :action => 'all_menu_courses'

  map.grades "grades", :controller => "users", :action => "grades"

  map.login "login", :controller => "pseudonym_sessions", :action => "new", :conditions => {:method => :get}
  map.connect "login", :controller => "pseudonym_sessions", :action=> "create", :conditions => {:method => :post}
  map.logout "logout", :controller => "pseudonym_sessions", :action => "destroy"
  map.cas_login "login/cas", :controller => "pseudonym_sessions", :action => "new", :conditions => {:method => :get}
  map.otp_login "login/otp", :controller => "pseudonym_sessions", :action => "otp_login", :conditions => { :method => [:get, :post] }
  map.aac_login "login/:account_authorization_config_id", :controller => "pseudonym_sessions", :action => "new", :conditions => {:method => :get}
  map.disable_mfa "users/:user_id/mfa", :controller => "pseudonym_sessions", :action => "disable_otp_login", :conditions => { :method => :delete }
  map.clear_file_session "file_session/clear", :controller => "pseudonym_sessions", :action => "clear_file_session"
  map.register "register", :controller => "users", :action => "new"
  map.register_from_website "register_from_website", :controller => "users", :action => "new"
  map.enroll 'enroll/:self_enrollment_code', :controller => 'self_enrollments', :action => 'new', :conditions => {:method => :get}
  map.enroll_frd 'enroll/:self_enrollment_code', :controller => 'self_enrollments', :action => 'create', :conditions => {:method => :post}
  map.services 'services', :controller => 'users', :action => 'services'
  map.bookmark_search 'search/bookmarks', :controller => 'users', :action => 'bookmark_search'
  map.search_rubrics 'search/rubrics', :controller => "search", :action => "rubrics"
  map.resources :users do |user|
    user.masquerade 'masquerade', :controller => 'users', :action => 'masquerade'
    user.delete 'delete', :controller => 'users', :action => 'delete'
    add_files(user, :images => true)
    add_zip_file_imports(user)
    user.resources :page_views, :only => 'index'
    user.resources :folders do |folder|
      folder.download 'download', :controller => 'folders', :action => 'download'
    end
    user.resources :calendar_events
    user.external_tool 'external_tools/:id', :controller => 'users', :action => 'external_tool'
    user.resources :rubrics
    user.resources :rubric_associations do |association|
      association.invite_assessor "invite", :controller => "rubric_assessments", :action => "invite"
      association.resources :rubric_assessments, :as => 'assessments'
    end
    user.resources :pseudonyms, :except => %w(index)
    user.resources :question_banks, :only => [:index]
    user.assignments_needing_grading 'assignments_needing_grading', :controller => 'users', :action => 'assignments_needing_grading'
    user.assignments_needing_submitting 'assignments_needing_submitting', :controller => 'users', :action => 'assignments_needing_submitting'
    user.admin_merge 'admin_merge', :controller => 'users', :action => 'admin_merge', :conditions => {:method => :get}
    user.merge 'merge', :controller => 'users', :action => 'merge', :conditions => {:method => :post}
    user.grades 'grades', :controller => 'users', :action => 'grades'
    user.resources :user_notes
    user.manageable_courses 'manageable_courses', :controller => 'users', :action => 'manageable_courses'
    user.outcomes 'outcomes', :controller => 'outcomes', :action => 'user_outcome_results'
    user.course_teacher_activity 'teacher_activity/course/:course_id', :controller => 'users', :action => 'teacher_activity'
    user.student_teacher_activity 'teacher_activity/student/:student_id', :controller => 'users', :action => 'teacher_activity'
    user.media_download 'media_download', :controller => 'users', :action => 'media_download'
    user.resources :messages, :only => [:index, :create] do |message|
      message.html_message "html_message", :controller => "messages", :action => "html_message", :conditions => {:method => :get}
    end
  end
  map.show_message_template 'show_message_template', :controller => 'messages', :action => 'show_message_template'
  map.message_templates 'message_templates', :controller => 'messages', :action => 'templates'

  map.resource :profile, :only => %w(show update),
               :controller => "profile",
               :member => { :update_profile => :put, :communication => :get, :communication_update => :put, :settings => :get } do |profile|
    profile.resources :pseudonyms, :except => %w(index)
    profile.resources :tokens, :except => %w(index)
    profile.pics 'profile_pictures', :controller => 'profile', :action => 'profile_pics'
    profile.user_service "user_services/:id", :controller => "users", :action => "delete_user_service", :conditions => {:method => :delete}
    profile.create_user_service "user_services", :controller => "users", :action => "create_user_service", :conditions => {:method => :post}
  end
  map.user_profile 'about/:id', :controller => :profile, :action => :show

  map.resources :communication_channels
  map.resource :pseudonym_session

  # dashboard_url is / , not /dashboard
  map.dashboard '', :controller => 'users', :action => 'user_dashboard', :conditions => {:method => :get}
  map.dashboard_sidebar 'dashboard-sidebar', :controller => 'users', :action => 'dashboard_sidebar', :conditions => {:method => :get}
  map.toggle_dashboard 'toggle_dashboard', :controller => 'users', :action => 'toggle_dashboard', :conditions => {:method => :post}
  map.styleguide 'styleguide', :controller => 'info', :action => 'styleguide', :conditions => {:method => :get}
  map.old_styleguide 'old_styleguide', :controller => 'info', :action => 'old_styleguide', :conditions => {:method => :get}
  map.root :dashboard
  # backwards compatibility with the old /dashboard url
  map.dashboard_redirect 'dashboard', :controller => 'users', :action => 'user_dashboard', :conditions => {:method => :get}

  # Thought this idea of having dashboard-scoped urls was a good idea at the
  # time... now I'm not as big a fan.
  map.resource :dashboard, :only => [] do |dashboard|
    add_files(dashboard)
    dashboard.close_notification 'account_notifications/:id', :controller => 'users', :action => 'close_notification', :conditions => {:method => :delete}
    dashboard.eportfolios "eportfolios", :controller => "eportfolios", :action => "user_index"
    dashboard.grades "grades", :controller => "users", :action => "grades"
    dashboard.resources :rubrics, :as => :assessments
    # comment_session can be removed once the iOS apps are no longer using it
    dashboard.comment_session "comment_session", :controller => "services_api", :action => "start_kaltura_session"
    dashboard.ignore_stream_item 'ignore_stream_item/:id', :controller => 'users', :action => 'ignore_stream_item', :conditions => {:method => :delete}
  end

  map.resources :plugins, :only => [:index, :show, :update]

  map.calendar 'calendar', :controller => 'calendars', :action => 'show', :conditions => { :method => :get }
  map.calendar2 'calendar2', :controller => 'calendars', :action => 'show2', :conditions => { :method => :get }
  map.course_section_calendar_event 'course_sections/:course_section_id/calendar_events/:id', :controller => :calendar_events, :action => 'show', :conditions => { :method => :get }
  map.switch_calendar 'switch_calendar/:preferred_calendar', :controller => 'calendars', :action => 'switch_calendar', :conditions => { :method => :post }
  map.files 'files', :controller => 'files', :action => 'full_index', :conditions => { :method => :get }
  map.s3_success 'files/s3_success/:id', :controller => 'files', :action => 's3_success'
  map.public_url 'files/:id/public_url.:format', :controller => 'files', :action => 'public_url'
  map.file_preflight 'files/preflight', :controller => 'files', :action => 'preflight'
  map.file_create_pending 'files/pending', :controller=> 'files', :action => 'create_pending'
  map.assignments 'assignments', :controller => 'assignments', :action => 'index', :conditions => { :method => :get }

  map.resources :appointment_groups, :only => [:index, :show]

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  map.errors "errors", :controller => "info", :action => "record_error", :conditions => {:method => :post}
  map.record_js_error 'record_js_error', :controller => 'info', :action => 'record_js_error', :conditions => { :method => :get }
  map.resources :errors, :as => :error_reports, :only => [:show, :index]

  map.health_check "health_check", :controller => 'info', :action => 'health_check'

  map.facebook "facebook", :controller => "facebook", :action => "index"
  map.facebook_hide_message "facebook/message/:id", :controller => "facebook", :action => "hide_message"
  map.facebook_settings "facebook/settings", :controller => "facebook", :action => "settings"
  map.facebook_notification_preferences "facebook/notification_preferences", :controller => "facebook", :action => "notification_preferences"

  map.resources :interaction_tests, :collection => {:next => :get, :register => :get, :groups => :post}

  map.object_snippet 'object_snippet', :controller => 'context', :action => 'object_snippet', :conditions => { :method => :post }
  map.saml_consume "saml_consume", :controller => "pseudonym_sessions", :action => "saml_consume"
  map.saml_logout "saml_logout", :controller => "pseudonym_sessions", :action => "saml_logout"
  map.saml_meta_data "saml_meta_data", :controller => 'accounts', :action => 'saml_meta_data'

  # Routes for course exports
  map.connect 'xsd/:version.xsd', :controller => 'content_exports', :action => 'xml_schema'

  map.resources :jobs, :only => %w(index show), :collection => %w[batch_update]

  Jammit::Routes.draw(map) if defined?(Jammit)

  ### API routes ###

  ApiRouteSet::V1.route(map) do |api|
    api.with_options(:controller => :courses) do |courses|
      courses.get 'courses', :action => :index
      courses.post 'accounts/:account_id/courses', :action => :create
      courses.put 'courses/:id', :action => :update
      courses.get 'courses/:id', :action => :show
      courses.get 'courses/:course_id/students', :action => :students
      courses.get 'courses/:course_id/settings', :action => :settings, :path_name => 'course_settings'
      courses.put 'courses/:course_id/settings', :action => :update_settings
      courses.get 'courses/:course_id/recent_students', :action => :recent_students, :path_name => 'course_recent_students'
      courses.get 'courses/:course_id/users', :action => :users, :path_name => 'course_users'
      courses.get 'courses/:course_id/users/:id', :action => :user, :path_name => 'course_user'
      courses.get 'courses/:course_id/search_users', :action => :search_users, :path_name => 'course_search_users'
      courses.get 'courses/:course_id/activity_stream', :action => :activity_stream, :path_name => 'course_activity_stream'
      courses.get 'courses/:course_id/todo', :action => :todo_items
      courses.delete 'courses/:id', :action => :destroy
      courses.post 'courses/:course_id/course_copy', :controller => :content_imports, :action => :copy_course_content
      courses.get 'courses/:course_id/course_copy/:id', :controller => :content_imports, :action => :copy_course_status, :path_name => :course_copy_status
      courses.post 'courses/:course_id/files', :action => :create_file
      courses.post 'courses/:course_id/folders', :controller => :folders, :action => :create
      courses.get  'courses/:course_id/folders/:id', :controller => :folders, :action => :show, :path_name => 'course_folder'
      courses.put  'accounts/:account_id/courses', :action => :batch_update
    end

    api.with_options(:controller => :tabs) do |tabs|
      tabs.get "courses/:course_id/tabs", :action => :index, :path_name => 'course_tabs'
      tabs.get "groups/:group_id/tabs", :action => :index, :path_name => 'group_tabs'
    end

    api.with_options(:controller => :sections) do |sections|
      sections.get 'courses/:course_id/sections', :action => :index, :path_name => 'course_sections'
      sections.get 'courses/:course_id/sections/:id', :action => :show, :path_name => 'course_section'
      sections.get 'sections/:id', :action => :show
      sections.post 'courses/:course_id/sections', :action => :create
      sections.put 'sections/:id', :action => :update
      sections.delete 'sections/:id', :action => :destroy
      sections.post 'sections/:id/crosslist/:new_course_id', :action => :crosslist
      sections.delete 'sections/:id/crosslist', :action => :uncrosslist
    end

    api.with_options(:controller => :enrollments_api) do |enrollments|
      enrollments.get  'courses/:course_id/enrollments', :action => :index, :path_name => 'course_enrollments'
      enrollments.get  'sections/:section_id/enrollments', :action => :index, :path_name => 'section_enrollments'
      enrollments.get  'users/:user_id/enrollments', :action => :index, :path_name => 'user_enrollments'

      enrollments.post 'courses/:course_id/enrollments', :action => :create
      enrollments.post 'sections/:section_id/enrollments', :action => :create

      enrollments.delete 'courses/:course_id/enrollments/:id', :action => :destroy
    end

    api.with_options(:controller => :assignments_api) do |assignments|
      assignments.get 'courses/:course_id/assignments', :action => :index, :path_name => 'course_assignments'
      assignments.get 'courses/:course_id/assignments/:id', :action => :show, :path_name => 'course_assignment'
      assignments.post 'courses/:course_id/assignments', :action => :create
      assignments.put 'courses/:course_id/assignments/:id', :action => :update
      assignments.delete 'courses/:course_id/assignments/:id', :action => :destroy, :controller => :assignments
    end

    api.with_options(:controller => :assignment_overrides) do |overrides|
      overrides.get 'courses/:course_id/assignments/:assignment_id/overrides', :action => :index
      overrides.post 'courses/:course_id/assignments/:assignment_id/overrides', :action => :create
      overrides.get 'courses/:course_id/assignments/:assignment_id/overrides/:id', :action => :show, :path_name => 'assignment_override'
      overrides.put 'courses/:course_id/assignments/:assignment_id/overrides/:id', :action => :update
      overrides.delete 'courses/:course_id/assignments/:assignment_id/overrides/:id', :action => :destroy
      overrides.get 'sections/:course_section_id/assignments/:assignment_id/override', :action => :section_alias
      overrides.get 'groups/:group_id/assignments/:assignment_id/override', :action => :group_alias
    end

    api.with_options(:controller => :submissions_api) do |submissions|
      def submissions_api(submissions, context)
        submissions.get "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions", :action => :index, :path_name => "#{context}_assignment_submissions"
        submissions.get "#{context.pluralize}/:#{context}_id/students/submissions", :controller => :submissions_api, :action => :for_students, :path_name => "#{context}_student_submissions"
        submissions.get "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:id", :action => :show, :path_name => "#{context}_assignment_submission"
        submissions.post "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions", :action => :create, :controller => :submissions
        submissions.post "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id/files", :action => :create_file
        submissions.put "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:id", :action => :update, :path_name => "#{context}_assignment_submission"
      end
      submissions_api(submissions, "course")
      submissions_api(submissions, "section")
    end

    api.with_options(:controller => :gradebook_history_api) do |gradebook_history|
      gradebook_history.get "courses/:course_id/gradebook_history/days", :action => :days, :path_name => 'gradebook_history'
      gradebook_history.get "courses/:course_id/gradebook_history/feed", :action => :feed, :path_name => 'gradebook_history_feed'
      gradebook_history.get "courses/:course_id/gradebook_history/:date", :action =>:day_details, :path_name => 'gradebook_history_for_day'
      gradebook_history.get "courses/:course_id/gradebook_history/:date/graders/:grader_id/assignments/:assignment_id/submissions", :action => :submissions, :path_name => 'gradebook_history_submissions'
    end

    api.get 'courses/:course_id/assignment_groups', :controller => :assignment_groups, :action => :index, :path_name => 'course_assignment_groups'

    api.with_options(:controller => :discussion_topics) do |topics|
      topics.get 'courses/:course_id/discussion_topics', :action => :index, :path_name => 'course_discussion_topics'
      topics.get 'groups/:group_id/discussion_topics', :action => :index, :path_name => 'group_discussion_topics'
    end

    api.with_options(:controller => :content_migrations) do |cm|
      cm.get 'courses/:course_id/content_migrations/migrators', :action => :available_migrators, :path_name => 'course_content_migration_migrators_list'
      cm.get 'courses/:course_id/content_migrations/:id', :action => :show, :path_name => 'course_content_migration'
      cm.get 'courses/:course_id/content_migrations', :action => :index, :path_name => 'course_content_migration_list'
      cm.post 'courses/:course_id/content_migrations', :action => :create, :path_name => 'course_content_migration_create'
      cm.put 'courses/:course_id/content_migrations/:id', :action => :update, :path_name => 'course_content_migration_update'
    end

    api.with_options(:controller => :migration_issues) do |mi|
      mi.get 'courses/:course_id/content_migrations/:content_migration_id/migration_issues/:id', :action => :show, :path_name => 'course_content_migration_migration_issue'
      mi.get 'courses/:course_id/content_migrations/:content_migration_id/migration_issues', :action => :index, :path_name => 'course_content_migration_migration_issue_list'
      mi.post 'courses/:course_id/content_migrations/:content_migration_id/migration_issues', :action => :create, :path_name => 'course_content_migration_migration_issue_create'
      mi.put 'courses/:course_id/content_migrations/:content_migration_id/migration_issues/:id', :action => :update, :path_name => 'course_content_migration_migration_issue_update'
    end

    api.with_options(:controller => :discussion_topics_api) do |topics|
      def topic_routes(topics, context)
        topics.get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id", :action => :show, :path_name => "#{context}_discussion_topic"
        topics.post "#{context.pluralize}/:#{context}_id/discussion_topics", :controller => :discussion_topics, :action => :create
        topics.put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id", :controller => :discussion_topics, :action => :update
        topics.delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id", :controller => :discussion_topics, :action => :destroy

        topics.get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/view", :action => :view, :path_name => "#{context}_discussion_topic_view"

        topics.get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entry_list", :action => :entry_list, :path_name => "#{context}_discussion_topic_entry_list"
        topics.post "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries", :action => :add_entry, :path_name => "#{context}_discussion_add_entry"
        topics.get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries", :action => :entries, :path_name => "#{context}_discussion_entries"
        topics.post "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/replies", :action => :add_reply, :path_name => "#{context}_discussion_add_reply"
        topics.get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/replies", :action => :replies, :path_name => "#{context}_discussion_replies"
        topics.put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:id", :controller => :discussion_entries, :action => :update, :path_name => "#{context}_discussion_update_reply"
        topics.delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:id", :controller => :discussion_entries, :action => :destroy, :path_name => "#{context}_discussion_delete_reply"

        topics.put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read", :action => :mark_topic_read, :path_name => "#{context}_discussion_topic_mark_read"
        topics.delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read", :action => :mark_topic_unread, :path_name => "#{context}_discussion_topic_mark_unread"
        topics.put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read_all", :action => :mark_all_read, :path_name => "#{context}_discussion_topic_mark_all_read"
        topics.delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read_all", :action => :mark_all_unread, :path_name => "#{context}_discussion_topic_mark_all_unread"
        topics.put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/read", :action => :mark_entry_read, :path_name => "#{context}_discussion_topic_discussion_entry_mark_read"
        topics.delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/read", :action => :mark_entry_unread, :path_name => "#{context}_discussion_topic_discussion_entry_mark_unread"
      end
      topic_routes(topics, "course")
      topic_routes(topics, "group")
      topic_routes(topics, "collection_item")
    end

    api.with_options(:controller => :collaborations) do |collaborations|
      collaborations.get 'collaborations/:id/members', :action => :members, :path_name => 'collaboration_members'
    end

    api.with_options(:controller => :external_tools) do |tools|
      def et_routes(route_object, context)
        route_object.get "#{context}s/:#{context}_id/external_tools/:external_tool_id", :action => :show, :path_name => "#{context}_external_tool_show"
        route_object.get "#{context}s/:#{context}_id/external_tools", :action => :index, :path_name => "#{context}_external_tools"
        route_object.post "#{context}s/:#{context}_id/external_tools", :action => :create, :path_name => "#{context}_external_tools_create"
        route_object.put "#{context}s/:#{context}_id/external_tools/:external_tool_id", :action => :update, :path_name => "#{context}_external_tools_update"
        route_object.delete "#{context}s/:#{context}_id/external_tools/:external_tool_id", :action => :destroy, :path_name => "#{context}_external_tools_delete"
      end
      et_routes(tools, "course")
      et_routes(tools, "account")
    end

    api.with_options(:controller => :external_feeds) do |feeds|
      def ef_routes(route_object, context)
        route_object.get "#{context}s/:#{context}_id/external_feeds", :action => :index, :path_name => "#{context}_external_feeds"
        route_object.post "#{context}s/:#{context}_id/external_feeds", :action => :create, :path_name => "#{context}_external_feeds_create"
        route_object.delete "#{context}s/:#{context}_id/external_feeds/:external_feed_id", :action => :destroy, :path_name => "#{context}_external_feeds_delete"
      end
      ef_routes(feeds, "course")
      ef_routes(feeds, "group")
    end

    api.with_options(:controller => :sis_imports_api) do |sis|
      sis.post 'accounts/:account_id/sis_imports', :action => :create
      sis.get 'accounts/:account_id/sis_imports/:id', :action => :show
    end

    api.with_options(:controller => :users) do |users|
      users.get 'users/self/activity_stream', :action => :activity_stream, :path_name => 'user_activity_stream'
      users.get 'users/activity_stream', :action => :activity_stream # deprecated

      users.put "users/:user_id/followers/self", :action => :follow
      users.delete "users/:user_id/followers/self", :action => :unfollow

      users.get 'users/self/todo', :action => :todo_items
      users.get 'users/self/upcoming_events', :action => :upcoming_events

      users.delete 'users/self/todo/:asset_string/:purpose', :action => :ignore_item, :path_name => 'users_todo_ignore'
      users.post 'accounts/:account_id/users', :action => :create
      users.get 'accounts/:account_id/users', :action => :index, :path_name => 'account_users'
      users.delete 'accounts/:account_id/users/:id', :action => :destroy

      users.put 'users/:id', :action => :update
      users.post 'users/:user_id/files', :action => :create_file

      users.post 'users/:user_id/folders', :controller => :folders, :action => :create
      users.get 'users/:user_id/folders/:id', :controller => :folders, :action => :show, :path_name => 'user_folder'

      users.get 'users/:id/settings', controller: 'users', action: 'settings'
      users.put 'users/:id/settings', controller: 'users', action: 'settings', path_name: 'user_settings'
    end

    api.with_options(:controller => :pseudonyms) do |pseudonyms|
      pseudonyms.get 'accounts/:account_id/logins', :action => :index, :path_name => 'account_pseudonyms'
      pseudonyms.get 'users/:user_id/logins', :action => :index, :path_name => 'user_pseudonyms'
      pseudonyms.post 'accounts/:account_id/logins', :action => :create
      pseudonyms.put 'accounts/:account_id/logins/:id', :action => :update
      pseudonyms.delete 'users/:user_id/logins/:id', :action => :destroy
    end

    api.with_options(:controller => :accounts) do |accounts|
      accounts.get 'accounts', :action => :index, :path_name => :accounts
      accounts.get 'accounts/:id', :action => :show
      accounts.put 'accounts/:id', :action => :update
      accounts.get 'accounts/:account_id/courses', :action => :courses_api, :path_name => 'account_courses'
      accounts.get 'accounts/:account_id/sub_accounts', :action => :sub_accounts, :path_name => 'sub_accounts'
      accounts.get 'accounts/:account_id/courses/:id', :controller => :courses, :action => :show, :path_name => 'account_course_show'
    end

    api.with_options(:controller => :role_overrides) do |roles|
      roles.get 'accounts/:account_id/roles', :action => :api_index, :path_name => 'account_roles'
      roles.get 'accounts/:account_id/roles/:role', :action => :show
      roles.post 'accounts/:account_id/roles', :action => :add_role
      roles.post 'accounts/:account_id/roles/:role/activate', :action => :activate_role
      roles.put 'accounts/:account_id/roles/:role', :action => :update
      roles.delete 'accounts/:account_id/roles/:role', :action => :remove_role
    end

    api.with_options(:controller => :account_reports) do |reports|
      reports.get 'accounts/:account_id/reports/:report', :action => :index
      reports.get 'accounts/:account_id/reports', :action => :available_reports
      reports.get 'accounts/:account_id/reports/:report/:id', :action => :show
      reports.post 'accounts/:account_id/reports/:report', :action => :create
      reports.delete 'accounts/:account_id/reports/:report/:id', :action => :destroy
    end

    api.with_options(:controller => :admins) do |admins|
      admins.post 'accounts/:account_id/admins', :action => :create
      admins.delete 'accounts/:account_id/admins/:user_id', :action => :destroy
      admins.get 'accounts/:account_id/admins', :action => :index, :path_name => 'account_admins'
    end

    api.with_options(:controller => :account_authorization_configs) do |authorization_configs|
      authorization_configs.get 'accounts/:account_id/account_authorization_configs/discovery_url', :action => :show_discovery_url
      authorization_configs.put 'accounts/:account_id/account_authorization_configs/discovery_url', :action => :update_discovery_url, :path_name => 'account_update_discovery_url'
      authorization_configs.delete 'accounts/:account_id/account_authorization_configs/discovery_url', :action => :destroy_discovery_url, :path_name => 'account_destroy_discovery_url'

      authorization_configs.get 'accounts/:account_id/account_authorization_configs', :action => :index
      authorization_configs.get 'accounts/:account_id/account_authorization_configs/:id', :action => :show
      authorization_configs.post 'accounts/:account_id/account_authorization_configs', :action => :create, :path_name => 'account_create_aac'
      authorization_configs.put 'accounts/:account_id/account_authorization_configs/:id', :action => :update, :path_name => 'account_update_aac'
      authorization_configs.delete 'accounts/:account_id/account_authorization_configs/:id', :action => :destroy, :path_name => 'account_delete_aac'
    end

    api.get 'users/:user_id/page_views', :controller => :page_views, :action => :index, :path_name => 'user_page_views'
    api.get 'users/:user_id/profile', :controller => :profile, :action => :settings
    api.get 'users/:user_id/avatars', :controller => :profile, :action => :profile_pics

    # deprecated routes, second one is solely for YARD. preferred API is api/v1/search/recipients
    api.get 'conversations/find_recipients', :controller => :search, :action => :recipients
    api.get 'conversations/find_recipients', :controller => :conversations, :action => :find_recipients

    api.with_options(:controller => :conversations) do |conversations|
      conversations.get 'conversations', :action => :index, :path_name => 'conversations'
      conversations.post 'conversations', :action => :create
      conversations.post 'conversations/mark_all_as_read', :action => :mark_all_as_read
      conversations.get 'conversations/batches', :action => :batches, :path_name => 'conversations_batches'
      conversations.get 'conversations/:id', :action => :show
      conversations.put 'conversations/:id', :action => :update # stars, subscribed-ness, workflow_state
      conversations.delete 'conversations/:id', :action => :destroy
      conversations.post 'conversations/:id/add_message', :action => :add_message
      conversations.post 'conversations/:id/add_recipients', :action => :add_recipients
      conversations.post 'conversations/:id/remove_messages', :action => :remove_messages
      conversations.put 'conversations', :action => :batch_update
      conversations.delete 'conversations/:id/delete_for_all', :action => :delete_for_all
    end

    api.with_options(:controller => :communication_channels) do |channels|
      channels.get 'users/:user_id/communication_channels', :action => :index, :path_name => 'communication_channels'
      channels.post 'users/:user_id/communication_channels', :action => :create
      channels.delete 'users/:user_id/communication_channels/:id', :action => :destroy
    end

    api.with_options(:controller => :comm_messages_api) do |comm_messages|
      comm_messages.get 'comm_messages', :action => :index, :path_name => 'comm_messages'
    end

    api.with_options(:controller => :services_api) do |services|
      services.get 'services/kaltura', :action => :show_kaltura_config
      services.post 'services/kaltura_session', :action => :start_kaltura_session
    end

    api.with_options(:controller => :calendar_events_api) do |events|
      events.get 'calendar_events', :action => :index, :path_name => 'calendar_events'
      events.post 'calendar_events', :action => :create
      events.get 'calendar_events/:id', :action => :show, :path_name => 'calendar_event'
      events.put 'calendar_events/:id', :action => :update
      events.delete 'calendar_events/:id', :action => :destroy
      events.post 'calendar_events/:id/reservations', :action => :reserve
      events.post 'calendar_events/:id/reservations/:participant_id', :action => :reserve, :path_name => 'calendar_event_reserve'
    end

    api.with_options(:controller => :appointment_groups) do |appt_groups|
      appt_groups.get 'appointment_groups', :action => :index, :path_name => 'appointment_groups'
      appt_groups.post 'appointment_groups', :action => :create
      appt_groups.get 'appointment_groups/:id', :action => :show, :path_name => 'appointment_group'
      appt_groups.put 'appointment_groups/:id', :action => :update
      appt_groups.delete 'appointment_groups/:id', :action => :destroy
      appt_groups.get 'appointment_groups/:id/users', :action => :users, :path_name => 'appointment_group_users'
      appt_groups.get 'appointment_groups/:id/groups', :action => :groups, :path_name => 'appointment_group_groups'
    end

    api.with_options(:controller => :groups) do |groups|
      groups.resources :groups, :except => [:index]
      groups.get 'users/self/groups', :action => :index, :path_name => "current_user_groups"
      groups.get 'accounts/:account_id/groups', :action => :context_index, :path_name => 'account_user_groups'
      groups.get 'courses/:course_id/groups', :action => :context_index, :path_name => 'course_user_groups'
      groups.get 'groups/:group_id/users', :action => :users, :path_name => 'group_users'
      groups.post 'groups/:group_id/invite', :action => :invite
      groups.post 'groups/:group_id/files', :action => :create_file
      groups.post 'group_categories/:group_category_id/groups', :action => :create
      groups.get 'groups/:group_id/activity_stream', :action => :activity_stream, :path_name => 'group_activity_stream'
      groups.put "groups/:group_id/followers/self", :action => :follow
      groups.delete "groups/:group_id/followers/self", :action => :unfollow

      groups.with_options(:controller => :group_memberships) do |memberships|
        memberships.resources :memberships, :path_prefix => "groups/:group_id", :name_prefix => "group_", :controller => :group_memberships, :except => [:show]
      end

      groups.post 'groups/:group_id/folders', :controller => :folders, :action => :create
      groups.get 'groups/:group_id/folders/:id', :controller => :folders, :action => :show, :path_name => 'group_folder'
    end

    api.with_options(:controller => :collections) do |collections|
      collections.get "collections", :action => :list, :path_name => 'collections'
      collections.resources :collections, :path_prefix => "users/:user_id", :name_prefix => "user_", :only => [:index, :create]
      collections.resources :collections, :path_prefix => "groups/:group_id", :name_prefix => "group_", :only => [:index, :create]
      collections.resources :collections, :except => [:index, :create]
      collections.put "collections/:collection_id/followers/self", :action => :follow
      collections.delete "collections/:collection_id/followers/self", :action => :unfollow

      collections.with_options(:controller => :collection_items) do |items|
        items.get "collections/:collection_id/items", :action => :index, :path_name => 'collection_items_list'
        items.resources :items, :path_prefix => "collections/:collection_id", :name_prefix => "collection_", :controller => :collection_items, :only => [:index, :create]
        items.resources :items, :path_prefix => "collections", :name_prefix => "collection_", :controller => :collection_items, :except => [:index, :create]
        items.put "collections/items/:item_id/upvotes/self", :action => :upvote
        items.delete "collections/items/:item_id/upvotes/self", :action => :remove_upvote
      end
    end

    api.with_options(:controller => :developer_keys) do |keys|
      keys.get 'developer_keys', :action => :index
      keys.get 'developer_keys/:id', :action => :show
      keys.delete 'developer_keys/:id', :action => :destroy
      keys.put 'developer_keys/:id', :action => :update
      keys.post 'developer_keys', :action => :create
    end

    api.with_options(:controller => :search) do |search|
      search.get 'search/rubrics', :action => 'rubrics', :path_name => 'search_rubrics'
      search.get 'search/recipients', :action => 'recipients', :path_name => 'search_recipients'
    end

    api.post 'files/:id/create_success', :controller => :files, :action => :api_create_success, :path_name => 'files_create_success'
    api.get 'files/:id/create_success', :controller => :files, :action => :api_create_success, :path_name => 'files_create_success'

    api.with_options(:controller => :files) do |files|
      files.post 'files/:id/create_success', :action => :api_create_success, :path_name => 'files_create_success'
      files.get 'files/:id/create_success', :action => :api_create_success, :path_name => 'files_create_success'
      # 'attachment' (rather than 'file') is used below so modules API can use polymorphic_url to generate an item API link
      files.get 'files/:id', :action => :api_show, :path_name => 'attachment'
      files.delete 'files/:id', :action => :destroy
      files.put 'files/:id', :action => :api_update
      files.get 'files/:id/:uuid/status', :action => :api_file_status, :path_name => 'file_status'
    end

    api.with_options(:controller => :folders) do |folders|
      folders.get 'folders/:id', :action => :show
      folders.get 'folders/:id/folders', :action => :api_index, :path_name => 'list_folders'
      folders.get 'folders/:id/files', :controller => :files, :action => :api_index, :path_name => 'list_files'
      folders.delete 'folders/:id', :action => :api_destroy
      folders.put 'folders/:id', :action => :update
      folders.post 'folders/:folder_id/folders', :action => :create, :path_name => 'create_folder'
      folders.post 'folders/:folder_id/files', :action => :create_file
    end

    api.with_options(:controller => :favorites) do |favorites|
      favorites.get "users/self/favorites/courses", :action => :list_favorite_courses, :path_name => :list_favorite_courses
      favorites.post "users/self/favorites/courses/:id", :action => :add_favorite_course
      favorites.delete "users/self/favorites/courses/:id", :action => :remove_favorite_course
      favorites.delete "users/self/favorites/courses", :action => :reset_course_favorites
    end

    api.with_options(:controller => :wiki_pages_api) do |wiki_pages|
      wiki_pages.get "courses/:course_id/pages", :action => :index, :path_name => 'course_wiki_pages'
      wiki_pages.get "groups/:group_id/pages", :action => :index, :path_name => 'group_wiki_pages'
      wiki_pages.get "courses/:course_id/pages/:url", :action => :show, :path_name => 'course_wiki_page'
      wiki_pages.get "groups/:group_id/pages/:url", :action => :show, :path_name => 'group_wiki_page'
      wiki_pages.post "courses/:course_id/pages", :action => :create
      wiki_pages.post "groups/:group_id/pages", :action => :create
      wiki_pages.put "courses/:course_id/pages/:url", :action => :update
      wiki_pages.put "groups/:group_id/pages/:url", :action => :update
      wiki_pages.delete "courses/:course_id/pages/:url", :action => :destroy
      wiki_pages.delete "groups/:group_id/pages/:url", :action => :destroy
    end

    api.with_options(:controller => :context_modules_api) do |context_modules|
      context_modules.get "courses/:course_id/modules", :action => :index, :path_name => 'course_context_modules'
      context_modules.get "courses/:course_id/modules/:id", :action => :show, :path_name => 'course_context_module'
      context_modules.put "courses/:course_id/modules", :action => :batch_update
      context_modules.post "courses/:course_id/modules", :action => :create, :path_name => 'course_context_module_create'
      context_modules.put "courses/:course_id/modules/:id", :action => :update, :path_name => 'course_context_module_update'
      context_modules.delete "courses/:course_id/modules/:id", :action => :destroy
    end

    api.with_options(:controller => :context_module_items_api) do |context_module_items|
      context_module_items.get "courses/:course_id/modules/:module_id/items", :action => :index, :path_name => 'course_context_module_items'
      context_module_items.get "courses/:course_id/modules/:module_id/items/:id", :action => :show, :path_name => 'course_context_module_item'
      context_module_items.get "courses/:course_id/module_item_redirect/:id", :action => :redirect, :path_name => 'course_context_module_item_redirect'
      context_module_items.post "courses/:course_id/modules/:module_id/items", :action => :create, :path_name => 'course_context_module_items_create'
      context_module_items.put "courses/:course_id/modules/:module_id/items/:id", :action => :update, :path_name => 'course_context_module_item_update'
      context_module_items.delete "courses/:course_id/modules/:module_id/items/:id", :action => :destroy
    end

    api.with_options(:controller => :quizzes_api) do |quizzes|
      quizzes.get "courses/:course_id/quizzes", :action => :index, :path_name => 'course_quizzes'
      quizzes.post "courses/:course_id/quizzes", :action => :create, :path_name => 'course_quiz_create'
      quizzes.get "courses/:course_id/quizzes/:id", :action => :show, :path_name => 'course_quiz'
      quizzes.put "courses/:course_id/quizzes/:id", :action => :update, :path_name => 'course_quiz_update'
    end

    api.with_options(:controller => :quiz_reports) do |statistics|
      statistics.post "courses/:course_id/quizzes/:quiz_id/reports", :action => :create, :path_name => 'course_quiz_reports_create'
      statistics.get "courses/:course_id/quizzes/:quiz_id/reports/:id", :action => :show, :path_name => 'course_quiz_report'
    end

    api.with_options(:controller => :quiz_submissions_api) do |quiz_submissions|
      quiz_submissions.post 'courses/:course_id/quizzes/:quiz_id/quiz_submissions/self/files', :action => :create_file, :path_name => 'quiz_submission_create_file'
    end

    api.with_options(:controller => :outcome_groups_api) do |outcome_groups|
      def og_routes(route_object, context)
        prefix = (context == "global" ? context : "#{context}s/:#{context}_id")
        route_object.get "#{prefix}/root_outcome_group", :action => :redirect, :path_name => "#{context}_redirect"
        route_object.get "#{prefix}/outcome_groups/account_chain", :action => :account_chain, :path_name => "#{context}_account_chain"
        route_object.get "#{prefix}/outcome_groups/:id", :action => :show, :path_name => "#{context}_outcome_group"
        route_object.put "#{prefix}/outcome_groups/:id", :action => :update
        route_object.delete "#{prefix}/outcome_groups/:id", :action => :destroy
        route_object.get "#{prefix}/outcome_groups/:id/outcomes", :action => :outcomes, :path_name => "#{context}_outcome_group_outcomes"
        route_object.get "#{prefix}/outcome_groups/:id/available_outcomes", :action => :available_outcomes, :path_name => "#{context}_outcome_group_available_outcomes"
        route_object.post "#{prefix}/outcome_groups/:id/outcomes", :action => :link
        route_object.put "#{prefix}/outcome_groups/:id/outcomes/:outcome_id", :action => :link, :path_name => "#{context}_outcome_link"
        route_object.delete "#{prefix}/outcome_groups/:id/outcomes/:outcome_id", :action => :unlink
        route_object.get "#{prefix}/outcome_groups/:id/subgroups", :action => :subgroups, :path_name => "#{context}_outcome_group_subgroups"
        route_object.post "#{prefix}/outcome_groups/:id/subgroups", :action => :create
        route_object.post "#{prefix}/outcome_groups/:id/import", :action => :import, :path_name => "#{context}_outcome_group_import"
        route_object.post "#{prefix}/outcome_groups/:id/batch", :action => :batch, :path_name => "#{context}_outcome_group_batch"
      end

      og_routes(outcome_groups, 'global')
      og_routes(outcome_groups, 'account')
      og_routes(outcome_groups, 'course')
    end

    api.with_options(:controller => :outcomes_api) do |outcomes|
      outcomes.get "outcomes/:id", :action => :show, :path_name => "outcome"
      outcomes.put "outcomes/:id", :action => :update
      outcomes.delete "outcomes/:id", :action => :destroy
    end

    api.with_options(:controller => :group_categories) do |group_categories|
      group_categories.resources :group_categories, :except => [:index, :create]
      group_categories.get 'accounts/:account_id/group_categories', :action => :index, :path_name => 'account_group_categories'
      group_categories.get 'courses/:course_id/group_categories', :action => :index, :path_name => 'course_group_categories'
      group_categories.post 'accounts/:account_id/group_categories', :action => :create
      group_categories.post 'courses/:course_id/group_categories', :action => :create
      group_categories.get 'group_categories/:group_category_id/groups', :action => :groups, :path_name => 'group_category_groups'
    end

    api.with_options(:controller => :progress) do |progress|
      progress.get "progress/:id", :action => :show, :path_name => "progress"
    end

    api.with_options(:controller => :app_center) do |app_center|
      ['course', 'account'].each do |context|
        prefix = "#{context}s/:#{context}_id/app_center"
        app_center.get "#{prefix}/apps", :action => :index, :path_name => "#{context}_app_center_apps"
        app_center.get "#{prefix}/apps/:app_id/reviews", :action => :reviews, :path_name => "#{context}_app_center_app_reviews"
      end
    end
  end

  # this is not a "normal" api endpoint in the sense that it is not documented
  # or called directly, it's used as the redirect in the file upload process
  # for local files. it also doesn't use the normal oauth authentication
  # system, so we can't put it in the api uri namespace.
  map.api_v1_files_create 'files_api', :controller => 'files', :action => 'api_create', :conditions => { :method => :post }

  map.oauth2_auth 'login/oauth2/auth', :controller => 'pseudonym_sessions', :action => 'oauth2_auth', :conditions => { :method => :get }
  map.oauth2_token 'login/oauth2/token', :controller => 'pseudonym_sessions', :action => 'oauth2_token', :conditions => { :method => :post }
  map.oauth2_auth_confirm 'login/oauth2/confirm', :controller => 'pseudonym_sessions', :action => 'oauth2_confirm', :conditions => { :method => :get }
  map.oauth2_auth_accept 'login/oauth2/accept', :controller => 'pseudonym_sessions', :action => 'oauth2_accept', :conditions => { :method => :post }
  map.oauth2_auth_deny 'login/oauth2/deny', :controller => 'pseudonym_sessions', :action => 'oauth2_deny', :conditions => { :method => :get }
  map.oauth2_logout 'login/oauth2/token', :controller => 'pseudonym_sessions', :action => 'oauth2_logout', :conditions => { :method => :delete }

  ApiRouteSet.route(map, "/api/lti/v1") do |lti|
    lti.post "tools/:tool_id/grade_passback", :controller => :lti_api, :action => :grade_passback, :path_name => "lti_grade_passback_api"
    lti.post "tools/:tool_id/ext_grade_passback", :controller => :lti_api, :action => :legacy_grade_passback, :path_name => "blti_legacy_grade_passback_api"
  end

  map.equation_images 'equation_images/:id', :controller => :equation_images, :action => :show, :id => /.+/

  # assignments at the top level (without a context) -- we have some specs that
  # assert these routes exist, but just 404. I'm not sure we ever actually want
  # top-level assignments available, maybe we should change the specs instead.
  map.resources :assignments, :only => %w(index show)

  map.resources :files do |file|
    file.download 'download', :controller => 'files', :action => 'show', :download => '1'
  end

  map.resources :developer_keys, :only => [:index]

  map.resources :rubrics do |rubric|
    rubric.resources :rubric_assessments, :as => 'assessments'
  end
  map.selection_test 'selection_test', :controller => 'external_content', :action => 'selection_test'

  map.resources :quiz_submissions do |submission|
    add_files(submission)
  end

  # commenting out all collection urls until collections are live
  # map.resources :collection_items, :only => [:new]
  # map.get_bookmarklet 'get_bookmarklet', :controller => 'collection_items', :action => 'get_bookmarklet'
  map.collection_item_link_data 'collection_items/link_data', :controller => 'collection_items', :action => 'link_data', :conditions => { :method => :post }
  #
  # map.resources :collections, :only => [:show, :index] do |collection|
  #   collection.resources :collection_items, :only => [:show, :index]
  # end

  # See how all your routes lay out with "rake routes"
end
