ActionController::Routing::Routes.draw do |map|

  map.resources :submission_comments, :only => :destroy

  map.mark_inbox_as_read 'inbox', :controller => 'context', :action => 'mark_inbox_as_read', :conditions => {:method => :delete}
  map.inbox 'inbox', :controller => 'context', :action => 'inbox'
  map.destroy_inbox_item 'inbox/:id', :controller => 'context', :action => 'destroy_inbox_item', :conditions => {:method => :delete}
  map.inbox_item 'inbox/:id', :controller => 'context', :action => 'inbox_item'

  map.discussion_replies 'conversations/discussion_replies', :controller => 'context', :action => 'discussion_replies'
  map.conversations_unread 'conversations/unread', :controller => 'conversations', :action => 'index', :scope => 'unread'
  map.conversations_labeled 'conversations/labeled', :controller => 'conversations', :action => 'index', :scope => 'labeled'
  map.conversations_archived 'conversations/archived', :controller => 'conversations', :action => 'index', :scope => 'archived'
  map.conversations_find_recipients 'conversations/find_recipients', :controller => 'conversations', :action => 'find_recipients'
  map.conversations_mark_all_as_read 'conversations/mark_all_as_read', :controller => 'conversations', :action => 'mark_all_as_read', :conditions => {:method => :post}
  map.conversations_watched_intro 'conversations/watched_intro', :controller => 'conversations', :action => 'watched_intro', :conditions => {:method => :post}
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
    :controller => 'communication_channels', :action => 're_send_confirmation'
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

  question_bank_resources = lambda do |bank|
    bank.bookmark 'bookmark', :controller => 'question_banks', :action => 'bookmark'
    bank.reorder 'reorder', :controller => 'question_banks', :action => 'reorder'
    bank.questions 'questions', :controller => 'question_banks', :action => 'questions'
    bank.move_questions 'move_questions', :controller => 'question_banks', :action => 'move_questions'
    bank.resources :assessment_questions do |question|
      question.move_question 'move', :controller => 'assessment_questions', :action => 'move'
    end
  end

  # There are a lot of resources that are all scoped to the course level
  # (assignments, files, wiki pages, user lists, forums, etc.).  Many of
  # these resources also apply to groups and individual users.  We call
  # courses, users, groups, or even accounts in this setting, "contexts".
  # There are some helper methods like the before_filter :get_context in application_controller
  # and the application_helper method :context_url to make retrieving
  # these contexts, and also generating context-specific urls, easier.
  map.resources :courses do |course|
    course.self_enrollment 'self_enrollment/:self_enrollment', :controller => 'courses', :action => 'self_enrollment'
    course.self_unenrollment 'self_unenrollment/:self_unenrollment', :controller => 'courses', :action => 'self_unenrollment'
    course.restore 'restore', :controller => 'courses', :action => 'restore'
    course.backup 'backup', :controller => 'courses', :action => 'backup'
    course.unconclude 'unconclude', :controller => 'courses', :action => 'unconclude'
    course.students 'students', :controller => 'courses', :action => 'students'
    course.enrollment_invitation 'enrollment_invitation', :controller => 'courses', :action => 'enrollment_invitation'
    course.users 'users', :controller => 'context', :action => 'roster'
    course.user_services 'user_services', :controller => 'context', :action => 'roster_user_services'
    course.user_usage 'users/:user_id/usage', :controller => 'context', :action => 'roster_user_usage'
    course.statistics 'statistics', :controller => 'courses', :action => 'statistics'
    course.prior_users 'users/prior', :controller => 'context', :action => 'prior_users'
    course.user 'users/:id', :controller => 'context', :action => 'roster_user', :conditions => {:method => :get}
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
    course.resources :zip_file_imports, :only => [:new, :create], :collection => [:import_status]
    course.import_files 'imports/files', :controller => 'content_imports', :action => 'files'
    course.import_quizzes 'imports/quizzes', :controller => 'content_imports', :action => 'quizzes'
    course.import_content 'imports/content', :controller => 'content_imports', :action => 'content'
    course.import_copy 'imports/copy', :controller => 'content_imports', :action => 'copy_course', :conditions => {:method => :get}
    course.import_migrate 'imports/migrate', :controller => 'content_imports', :action => 'migrate_content'
    course.import_upload 'imports/upload', :controller => 'content_imports', :action => 'migrate_content_upload'
    course.import_s3_success 'imports/s3_success', :controller => 'content_imports', :action => 'migrate_content_s3_success'
    course.import_copy_content 'imports/copy', :controller => 'content_imports', :action => 'copy_course_content', :conditions => {:method => :post}
    course.import_migrate_choose 'imports/migrate/:id', :controller => 'content_imports', :action => 'migrate_content_choose'
    course.import_migrate_execute 'imports/migrate/:id/execute', :controller => 'content_imports', :action => 'migrate_content_execute'
    course.import_review 'imports/review', :controller => 'content_imports', :action => 'review'
    course.import_list 'imports/list', :controller => 'content_imports', :action => 'index'
    course.import_copy_status 'imports/:id', :controller => 'content_imports', :action => 'copy_course_status', :conditions => {:method => :get}
    course.resource :gradebook_upload
    course.grades "grades", :controller => 'gradebooks', :action => 'grade_summary', :id => nil
    course.grading_rubrics "grading_rubrics", :controller => 'gradebooks', :action => 'grading_rubrics'
    course.student_grades "grades/:id", :controller => 'gradebooks', :action => 'grade_summary'
    course.resources :announcements
    course.announcements_external_feeds "announcements/external_feeds", :controller => 'announcements', :action => 'create_external_feed', :conditions => { :method => :post }
    course.announcements_external_feed "announcements/external_feeds/:id", :controller => 'announcements', :action => 'destroy_external_feed', :conditions => { :method => :delete }
    course.chat 'chat', :controller => 'context', :action => 'chat'
    course.formatted_chat 'chat.:format', :controller => 'context', :action => 'chat'
    course.old_calendar 'calendar', :controller => 'calendars', :action => 'show'
    course.locks 'locks', :controller => 'courses', :action => 'locks'
    course.resources :discussion_topics, :collection => {:reorder => :post} do |topic|
      topic.permissions 'permissions', :controller => 'discussion_topics', :action => 'permissions'
    end
    course.resources :discussion_entries
    course.resources :assignments, :collection => {:syllabus => :get, :submissions => :get}, :member => {:update_submission => :any} do |assignment|
      assignment.resources :submissions do |submission|
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
    course.resources :external_tools, :collection => {:retrieve => :get} do |tools|
      tools.resource_selection 'resource_selection', :controller => 'external_tools', :action => 'resource_selection'
      tools.finished 'finished', :controller => 'external_tools', :action => 'finished'
    end
    course.resources :submissions
    course.resources :calendar_events
    course.resources :chats
    course.resources :files, :collection => {:quota => :get, :reorder => :post} do |file|
      file.text_inline 'inline', :controller => 'files', :action => 'text_show'
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
      file.typed_download 'download.:type', :controller => 'files', :action => 'show', :download => '1'
      file.preview 'preview', :controller => 'files', :action => 'show', :preview => '1'
      file.inline_view 'inline_view', :controller => 'files', :action => 'show', :inline => '1'
      file.attachment_content 'contents', :controller => 'files', :action => 'attachment_content'
      file.relative_path ":file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    end
    course.images 'images', :controller => 'files', :action => 'images'
    course.relative_file_path "file_contents/:file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    course.resources :folders do |folder|
      folder.download 'download', :controller => 'folders', :action => 'download'
    end
    course.resources :groups, :collection => {:create_category => :post, :update_category => :put, :delete_category => :delete}
    course.resources :wiki_pages, :as => 'wiki' do |wiki_page|
      wiki_page.latest_version_number 'revisions/latest', :controller => 'wiki_page_revisions', :action => 'latest_version_number'
      wiki_page.resources :wiki_page_revisions, :as => "revisions"
      wiki_page.resources :wiki_page_comments, :as => "comments"
    end
    course.named_wiki_page 'wiki/:id', :id => /[^\/]+/, :controller => 'wiki_pages', :action => 'show'
    course.resources :conferences do |conference|
      conference.join "join", :controller => "conferences", :action => "join"
      conference.close "close", :controller => "conferences", :action => "close"
      conference.settings "settings", :controller => "conferences", :action => "settings"
    end

    course.resources :question_banks, &question_bank_resources

    course.quizzes_publish 'quizzes/publish', :controller => 'quizzes', :action => 'publish'
    course.resources :quizzes do |quiz|
      quiz.reorder "reorder", :controller => "quizzes", :action => "reorder"
      quiz.history "history", :controller => "quizzes", :action => "history"
      quiz.statistics "statistics", :controller => 'quizzes', :action => 'statistics'
      quiz.formatted_statistics "statistics.:format", :controller => 'quizzes', :action => 'statistics'
      quiz.read_only "read_only", :controller => 'quizzes', :action => 'read_only'
      quiz.filters 'filters', :controller => 'quizzes', :action => 'filters'
      quiz.resources :quiz_submissions, :as => "submissions", :collection => {:backup => :put} do |submission|
      end
      quiz.extensions 'extensions/:user_id', :controller => 'quiz_submissions', :action => 'extensions', :conditions => {:method => :post}
      quiz.resources :quiz_questions, :as => "questions", :only => %w(create update destroy show)
      quiz.resources :quiz_groups, :as => "groups", :only => %w(create update destroy) do |group|
        group.reorder "reorder", :controller => "quiz_groups", :action => "reorder"
      end
      quiz.take "take", :controller => "quizzes", :action => "show", :take => '1'
      quiz.moderate "moderate", :controller => "quizzes", :action => "moderate"
      quiz.lockdown_browser_required "lockdown_browser_required", :controller => "quizzes", :action => "lockdown_browser_required"
    end

    course.resources :collaborations
    course.resources :short_messages

    course.resources :gradebook_uploads
    course.resources :rubrics
    course.resources :rubric_associations do |association|
      association.invite_assessor "invite", :controller => "rubric_assessments", :action => "invite"
      association.remind_assessee "remind/:assessment_request_id", :controller => "rubric_assessments", :action => "remind"
      association.resources :rubric_assessments, :as => 'assessments'
    end
    course.user_outcomes_results 'outcomes/users/:user_id', :controller => 'outcomes', :action => 'user_outcome_results'
    course.outcomes_for_asset "outcomes/assets/:asset_string", :controller => 'outcomes', :action => 'outcomes_for_asset', :conditions => {:method => :get}
    course.update_outcomes_for_asset "outcomes/assets/:asset_string", :controller => 'outcomes', :action => 'update_outcomes_for_asset', :conditions => {:method => :post}
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
    course.media_download 'media_download', :controller => 'users', :action => 'media_download'
    course.typed_media_download 'media_download.:type', :controller => 'users', :action => 'media_download'
    course.group_unassigned_members 'group_unassigned_members', :controller => 'groups', :action => 'unassigned_members', :conditions => { :method => :get }
    course.group_unassigned_members 'group_unassigned_members.:format', :controller => 'groups', :action => 'unassigned_members', :conditions => { :method => :get }
    course.group_assign_unassigned_members 'group_assign_unassigned_members', :controller => 'groups', :action => 'assign_unassigned_members', :conditions => { :method => :post }
    course.user_notes 'user_notes', :controller => 'user_notes', :action => 'user_notes'
    course.switch_role 'switch_role/:role', :controller => 'courses', :action => 'switch_role'
    course.sis_publish_status 'details/sis_publish', :controller => 'courses', :action => 'sis_publish_status', :conditions => {:method => :get}
    course.publish_to_sis 'details/sis_publish', :controller => 'courses', :action => 'publish_to_sis', :conditions => {:method => :post}

    course.resources :user_lists, :only => :create
    course.reset 'reset', :controller => 'courses', :action => 'reset_content', :conditions => {:method => :post}
    course.resources :alerts
  end

  map.resources :page_views, :only => [:update,:index]
  map.create_media_object 'media_objects', :controller => 'context', :action => 'create_media_object', :conditions => {:method => :post}
  map.kaltura_notifications 'media_objects/kaltura_notifications', :controller => 'context', :action => 'kaltura_notifications'
  map.media_object 'media_objects/:id', :controller => 'context', :action => 'media_object_inline'
  map.media_object_redirect 'media_objects/:id/redirect', :controller => 'context', :action => 'media_object_redirect'
  map.media_object_thumbnail 'media_objects/:id/thumbnail', :controller => 'context', :action => 'media_object_thumbnail'

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
    feed.calendar "calendars/:feed_code", :controller => "calendars", :action => "public_feed"
    feed.calendar_format "calendars/:feed_code.:format", :controller => "calendars", :action => "public_feed"
    feed.forum "forums/:feed_code", :controller => "discussion_topics", :action => "public_feed"
    feed.forum_format "forums/:feed_code.:format", :controller => "discussion_topics", :action => "public_feed"
    feed.topic "topics/:discussion_topic_id/:feed_code", :controller => "discussion_entries", :action => "public_feed"
    feed.topic_format "topics/:discussion_topic_id/:feed_code.:format", :controller => "discussion_entries", :action => "public_feed"
    feed.files "files/:feed_code", :controller => "files", :action => "public_feed"
    feed.files_format "files/:feed_code.:format", :controller => "files", :action => "public_feed"
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
    feed.gradebook "gradebooks/:feed_code", :controller => "gradebooks", :action => "public_feed"
    feed.eportfolio "eportfolios/:eportfolio_id.:format", :controller => "eportfolios", :action => "public_feed"
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
    group.users 'users', :controller => 'context', :action => 'roster'
    group.user_services 'user_services', :controller => 'context', :action => 'roster_user_services'
    group.user_usage 'users/:user_id/usage', :controller => 'context', :action => 'roster_user_usage'
    group.user 'users/:id', :controller => 'context', :action => 'roster_user', :conditions => {:method => :get}
    group.remove_user 'remove_user/:id', :controller => 'groups', :action => 'remove_user', :conditions => {:method => :delete}
    group.add_user 'add_user', :controller => 'groups', :action => 'add_user'
    group.members 'members.:format', :controller => 'groups', :action => 'context_group_members', :conditions => {:method => :get}
    group.members 'members', :controller => 'groups', :action => 'context_group_members', :conditions => {:method => :get}
    group.resources :announcements
    group.resources :discussion_topics, :collection => {:reorder => :post} do |topic|
      topic.permissions 'permissions', :controller => 'discussion_topics', :action => 'permissions'
    end
    group.resources :discussion_entries
    group.resources :calendar_events
    group.resources :chats
    group.announcements_external_feeds "announcements/external_feeds", :controller => 'announcements', :action => 'create_external_feed', :conditions => { :method => :post }
    group.announcements_external_feed "announcements/external_feeds/:id", :controller => 'announcements', :action => 'destroy_external_feed', :conditions => { :method => :delete }
    group.resources :zip_file_imports, :only => [:new, :create], :collection => [:import_status]
    group.resources :files, :collection => {:quota => :get, :reorder => :post} do |file|
      file.text_inline 'inline', :controller => 'files', :action => 'text_show'
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
      file.typed_download 'download.:type', :controller => 'files', :action => 'show', :download => '1'
      file.preview 'preview', :controller => 'files', :action => 'show', :preview => '1'
      file.inline_view 'inline_view', :controller => 'files', :action => 'show', :inline => '1'
      file.attachment_content 'contents', :controller => 'files', :action => 'attachment_content'
      file.relative_path ":file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    end
    group.resources :external_tools, :only => [:show], :collection => {:retrieve => :get}
    group.images 'images', :controller => 'files', :action => 'images'
    group.resources :folders do |folder|
      folder.download 'download', :controller => 'folders', :action => 'download'
    end
    group.resources :wiki_pages, :as => 'wiki' do |wiki_page|
      wiki_page.latest_version_number 'revisions/latest', :controller => 'wiki_page_revisions', :action => 'latest_version_number'
      wiki_page.resources :wiki_page_revisions, :as => "revisions"
      wiki_page.resources :wiki_page_comments, :as => "comments"
    end
    group.named_wiki_page 'wiki/:id', :id => /[^\/]+/, :controller => 'wiki_pages', :action => 'show'
    group.resources :conferences do |conference|
      conference.join "join", :controller => "conferences", :action => "join"
      conference.close "close", :controller => "conferences", :action => "close"
      conference.settings "settings", :controller => "conferences", :action => "settings"
    end
    group.chat 'chat', :controller => 'context', :action => 'chat'
    group.formatted_chat 'chat.:format', :controller => 'context', :action => 'chat'

    group.media_download 'media_download', :controller => 'users', :action => 'media_download'
    group.typed_media_download 'media_download.:type', :controller => 'users', :action => 'media_download'
    group.resources :collaborations
    group.resources :short_messages
    group.old_calendar 'calendar', :controller => 'calendars', :action => 'show'
  end

  map.resources :accounts, :member => { :statistics => :get } do |account|
    account.settings 'settings', :controller => 'accounts', :action => 'settings'
    account.add_account_user 'account_users', :controller => 'accounts', :action => 'add_account_user', :conditions => {:method => :post}
    account.remove_account_user 'account_users/:id', :controller => 'accounts', :action => 'remove_account_user', :conditions => {:method => :delete}

    account.resources :grading_standards, :only => %w(index create update destroy)

    account.statistics 'statistics', :controller => 'accounts', :action => 'statistics'
    account.statistics_page_views 'statistics/page_views', :controller => 'accounts', :action => 'statistics_page_views'
    account.statistics_graph 'statistics/over_time/:attribute', :controller => 'accounts', :action => 'statistics_graph'
    account.formatted_statistics_graph 'statistics/over_time/:attribute.:format', :controller => 'accounts', :action => 'statistics_graph'
    account.turnitin_confirmation 'turnitin/:id/:shared_secret', :controller => 'accounts', :action => 'turnitin_confirmation'
    account.resources :permissions, :controller => 'role_overrides', :only => [:index, :create], :collection => {:add_role => :post, :remove_role => :delete}
    account.resources :role_overrides, :only => [:index, :create], :collection => {:add_role => :post, :remove_role => :delete}
    account.resources :terms
    account.resources :sub_accounts
    account.avatars 'avatars', :controller => 'accounts', :action => 'avatars'
    account.sis_import 'sis_import', :controller => 'accounts', :action => 'sis_import'
    account.sis_import_submit 'sis_import_submit', :controller => 'accounts', :action => 'sis_import_submit'
    account.add_user 'users', :controller => 'users', :action => 'create', :conditions => {:method => :post}
    account.confirm_delete_user 'users/:user_id/delete', :controller => 'accounts', :action => 'confirm_delete_user'
    account.delete_user 'users/:user_id', :controller => 'accounts', :action => 'remove_user', :conditions => {:method => :delete}
    account.resources :users
    account.resources :account_notifications, :only => [:create, :destroy]
    account.resources :announcements
    account.resources :assignments
    account.resources :submissions
    account.resources :account_authorization_configs
    account.update_all_authorization_configs 'account_authorization_configs', :controller => 'account_authorization_configs', :action => 'update_all', :conditions => {:method => :put}
    account.remove_all_authorization_configs 'account_authorization_configs', :controller => 'account_authorization_configs', :action => 'destroy_all', :conditions => {:method => :delete}
    account.test_ldap_connections 'test_ldap_connections', :controller => 'account_authorization_configs', :action => 'test_ldap_connection'
    account.test_ldap_binds 'test_ldap_binds', :controller => 'account_authorization_configs', :action => 'test_ldap_bind'
    account.test_ldap_searches 'test_ldap_searches', :controller => 'account_authorization_configs', :action => 'test_ldap_search'
    account.test_ldap_logins 'test_ldap_logins', :controller => 'account_authorization_configs', :action => 'test_ldap_login'
    account.resources :external_tools do |tools|
      tools.finished 'finished', :controller => 'external_tools', :action => 'finished'
    end
    account.resources :chats
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
    account.resources :zip_file_imports, :only => [:new, :create], :collection => [:import_status]
    account.resources :files, :collection => {:quota => :get, :reorder => :post, :list => :get} do |file|
      file.text_inline 'inline', :controller => 'files', :action => 'text_show'
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
      file.typed_download 'download.:type', :controller => 'files', :action => 'show', :download => '1'
      file.preview 'preview', :controller => 'files', :action => 'show', :preview => '1'
      file.inline_view 'inline_view', :controller => 'files', :action => 'show', :inline => '1'
      file.attachment_content 'contents', :controller => 'files', :action => 'attachment_content'
      file.relative_path ":file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    end
    account.relative_file_path "file_contents/:file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    account.resources :folders do |folder|
      folder.download 'download', :controller => 'folders', :action => 'download'
    end
    account.media_download 'media_download', :controller => 'users', :action => 'media_download'
    account.typed_media_download 'media_download.:type', :controller => 'users', :action => 'media_download'
    account.resources :groups, :collection => {:create_category => :post, :update_category => :put, :delete_category => :delete}
    account.resources :outcomes
    account.group_unassigned_members 'group_unassigned_members', :controller => 'groups', :action => 'unassigned_members', :conditions => { :method => :get }
    account.group_unassigned_members 'group_unassigned_members.:format', :controller => 'groups', :action => 'unassigned_members', :conditions => { :method => :get }
    account.group_assign_unassigned_members 'group_assign_unassigned_members', :controller => 'groups', :action => 'assign_unassigned_members', :conditions => { :method => :post }
    account.courses 'courses', :controller => 'accounts', :action => 'courses'
    account.courses_formatted 'courses.:format', :controller => 'accounts', :action => 'courses'
    account.courses_redirect 'courses/:id', :controller => 'accounts', :action => 'courses_redirect'
    account.user_notes 'user_notes', :controller => 'user_notes', :action => 'user_notes'
    account.run_report 'run_report', :controller => 'accounts', :action => 'run_report'
    account.resources :alerts
    account.resources :question_banks, &question_bank_resources
    account.resources :user_lists, :only => :create
  end
  map.avatar_image 'images/users/:user_id', :controller => 'info', :action => 'avatar_image_url', :conditions => {:method => :get}
  map.thumbnail_image 'images/thumbnails/:id/:uuid', :controller => 'files', :action => 'image_thumbnail'
  map.show_thumbnail_image 'images/thumbnails/show/:id/:uuid', :controller => 'files', :action => 'show_thumbnail'
  map.report_avatar_image 'images/users/:user_id/report', :controller => 'users', :action => 'report_avatar_image', :conditions => {:method => :post}
  map.update_avatar_image 'images/users/:user_id', :controller => 'users', :action => 'update_avatar_image', :conditions => {:method => :put}

  map.menu_courses 'menu_courses', :controller => 'users', :action => 'menu_courses'
  map.all_menu_courses 'all_menu_courses', :controller => 'users', :action => 'all_menu_courses'
  map.resources :favorites, :only => [:create, :destroy], :collection => 'reset'

  map.grades "grades", :controller => "users", :action => "grades"

  map.login "login", :controller => "pseudonym_sessions", :action => "new", :conditions => {:method => :get}
  map.connect "login", :controller => "pseudonym_sessions", :action=> "create", :conditions => {:method => :post}
  map.logout "logout", :controller => "pseudonym_sessions", :action => "destroy"
  map.clear_file_session "file_session/clear", :controller => "pseudonym_sessions", :action => "clear_file_session"
  map.register "register", :controller => "users", :action => "new"
  map.register_from_website "register_from_website", :controller => "users", :action => "new"
  map.registered "registered", :controller => "users", :action => "registered"
  map.services 'services', :controller => 'users', :action => 'services'
  map.bookmark_search 'search/bookmarks', :controller => 'users', :action => 'bookmark_search'
  map.search_rubrics 'search/rubrics', :controller => "search", :action => "rubrics"
  map.resources :users do |user|
    user.masquerade 'masquerade', :controller => 'users', :action => 'masquerade'
    user.delete 'delete', :controller => 'users', :action => 'delete'
    user.resources :files, :collection => {:quota => :get, :reorder => :post} do |file|
      file.text_inline 'inline', :controller => 'files', :action => 'text_show'
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
      file.typed_download 'download.:type', :controller => 'files', :action => 'show', :download => '1'
      file.preview 'preview', :controller => 'files', :action => 'show', :preview => '1'
      file.inline_view 'inline_view', :controller => 'files', :action => 'show', :inline => '1'
      file.attachment_content 'contents', :controller => 'files', :action => 'attachment_content'
      file.relative_path ":file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    end
    user.images 'images', :controller => 'files', :action => 'images'
    user.resources :page_views, :only => [:index]
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
    user.resources :pseudonyms
    user.resources :question_banks, :only => [:index]
    user.assignments_needing_grading 'assignments_needing_grading', :controller => 'users', :action => 'assignments_needing_grading'
    user.assignments_needing_submitting 'assignments_needing_submitting', :controller => 'users', :action => 'assignments_needing_submitting'
    user.admin_merge 'admin_merge', :controller => 'users', :action => 'admin_merge', :conditions => {:method => :get}
    user.confirm_merge 'merge', :controller => 'users', :action => 'confirm_merge', :conditions => {:method => :get}
    user.merge 'merge', :controller => 'users', :action => 'merge', :conditions => {:method => :post}
    user.grades 'grades', :controller => 'users', :action => 'grades'
    user.resources :user_notes
    user.manageable_courses 'manageable_courses', :controller => 'users', :action => 'manageable_courses'
    user.outcomes 'outcomes', :controller => 'outcomes', :action => 'user_outcome_results'
    user.resources :zip_file_imports, :only => [:new, :create], :collection => [:import_status]
    user.course_teacher_activity 'teacher_activity/course/:course_id', :controller => 'users', :action => 'teacher_activity'
    user.student_teacher_activity 'teacher_activity/student/:student_id', :controller => 'users', :action => 'teacher_activity'
    user.media_download 'media_download', :controller => 'users', :action => 'media_download'
  end
  map.resource :profile, :only => [:show, :update], :controller => "profile", :member => { :communication => :get, :update_communication => :post } do |profile|
    profile.resources :pseudonyms, :except => %w(index)
    profile.resources :tokens, :except => %w(index)
    profile.pics 'profile_pictures', :controller => 'profile', :action => 'profile_pics'
    profile.user_service "user_services/:id", :controller => "users", :action => "delete_user_service", :conditions => {:method => :delete}
    profile.create_user_service "user_services", :controller => "users", :action => "create_user_service", :conditions => {:method => :post}
  end
  map.resources :communication_channels
  map.resource :pseudonym_session

  # dashboard_url is / , not /dashboard
  map.dashboard '', :controller => 'users', :action => 'user_dashboard', :conditions => {:method => :get}
  map.root :dashboard
  # backwards compatibility with the old /dashboard url
  map.dashboard_redirect 'dashboard', :controller => 'users', :action => 'user_dashboard', :conditions => {:method => :get}

  # Thought this idea of having dashboard-scoped urls was a good idea at the
  # time... now I'm not as big a fan.
  map.resource :dashboard, :only => [] do |dashboard|
    dashboard.resources :files, :only => [:index,:show], :collection => {:quota => :get} do |file|
      file.text_inline 'inline', :controller => 'files', :action => 'text_show'
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
      file.typed_download 'download.:type', :controller => 'files', :action => 'show', :download => '1'
      file.preview 'preview', :controller => 'files', :action => 'show', :preview => '1'
      file.inline_view 'inline_view', :controller => 'files', :action => 'show', :inline => '1'
      file.attachment_content 'contents', :controller => 'files', :action => 'attachment_content'
      file.relative_path ":file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    end
    dashboard.close_notification 'account_notifications/:id', :controller => 'users', :action => 'close_notification', :conditions => {:method => :delete}
    dashboard.eportfolios "eportfolios", :controller => "eportfolios", :action => "user_index"
    dashboard.grades "grades", :controller => "users", :action => "grades"
    dashboard.resources :rubrics, :as => :assessments
    # comment_session can be removed once the iOS apps are no longer using it
    dashboard.comment_session "comment_session", :controller => "services_api", :action => "start_kaltura_session"
    dashboard.ignore_stream_item 'ignore_stream_item/:id', :controller => 'users', :action => 'ignore_stream_item', :conditions => {:method => :delete}
  end

  map.resources :plugins, :only => [:index, :show, :update]

  # The getting_started pages are a short wizard used to help
  # a teacher start a new course from scratch.
  map.getting_started_assignments 'getting_started/assignments',
    :controller => 'getting_started', :action => 'assignments', :conditions => { :method => :get }
  map.getting_started_teacherless 'getting_started/teacherless',
    :controller => 'getting_started', :action => 'teacherless', :conditions => { :method => :get }
  map.getting_started_students 'getting_started/students',
    :controller => 'getting_started', :action => 'students', :conditions => { :method => :get }
  map.getting_started_setup 'getting_started/setup',
    :controller => 'getting_started', :action => 'setup', :conditions => { :method => :get }
  map.getting_started 'getting_started',
    :controller => 'getting_started', :action => 'name', :conditions => { :method => :get }
  map.getting_started_name 'getting_started/name',
    :controller => 'getting_started', :action => 'name', :conditions => { :method => :get }
  map.getting_started_finalize 'getting_started/finalize',
    :controller => 'getting_started', :action => 'finalize', :conditions => { :method => :post }

  map.calendar 'calendar', :controller => 'calendars', :action => 'show', :conditions => { :method => :get }
  map.calendar2 'calendar2', :controller => 'calendars', :action => 'show2', :conditions => { :method => :get }
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

  map.resources :delayed_jobs, :only => :index, :controller => 'jobs'
  map.object_snippet 'object_snippet', :controller => 'context', :action => 'object_snippet', :conditions => { :method => :post }
  map.saml_consume "saml_consume", :controller => "pseudonym_sessions", :action => "saml_consume"
  map.saml_logout "saml_logout", :controller => "pseudonym_sessions", :action => "saml_logout"
  map.saml_meta_data "saml_meta_data", :controller => 'accounts', :action => 'saml_meta_data'

  # Routes for course exports
  map.connect 'xsd/:version.xsd', :controller => 'content_exports', :action => 'xml_schema'

  map.resources :jobs, :only => %w(index), :collection => %w[batch_update]

  Jammit::Routes.draw(map) if defined?(Jammit)

  ### API routes ###

  ApiRouteSet::V1.route(map) do |api|
    api.with_options(:controller => :courses) do |courses|
      courses.get 'courses', :action => :index
      courses.post 'accounts/:account_id/courses', :action => :create
      courses.get 'courses/:id', :action => :show
      courses.get 'courses/:course_id/sections', :action => :sections, :path_name => 'course_sections'
      courses.get 'courses/:course_id/students', :action => :students
      courses.get 'courses/:course_id/activity_stream', :action => :activity_stream
      courses.get 'courses/:course_id/todo', :action => :todo_items
      courses.post 'courses/:course_id/course_copy', :controller => :content_imports, :action => :copy_course_content
      courses.get 'courses/:course_id/course_copy/:id', :controller => :content_imports, :action => :copy_course_status, :path_name => :course_copy_status
    end

    api.with_options(:controller => :enrollments_api) do |enrollments|
      enrollments.post 'courses/:course_id/enrollments', :action => :create
    end

    api.with_options(:controller => :assignments_api) do |assignments|
      assignments.get 'courses/:course_id/assignments', :action => :index, :path_name => 'course_assignments'
      assignments.get 'courses/:course_id/assignments/:id', :action => :show
      assignments.post 'courses/:course_id/assignments', :action => :create
      assignments.put 'courses/:course_id/assignments/:id', :action => :update
    end

    api.with_options(:controller => :submissions_api) do |submissions|
      submissions.get 'courses/:course_id/assignments/:assignment_id/submissions', :action => :index, :path_name => 'course_assignment_submissions'
      submissions.get 'sections/:section_id/assignments/:assignment_id/submissions', :action => :index, :path_name => 'section_assignment_submissions'

      submissions.get 'courses/:course_id/students/submissions', :controller => :submissions_api, :action => :for_students, :path_name => 'course_student_submissions'
      submissions.get 'sections/:section_id/students/submissions', :controller => :submissions_api, :action => :for_students, :path_name => 'section_student_submissions'

      submissions.get 'courses/:course_id/assignments/:assignment_id/submissions/:id', :action => :show
      submissions.get 'sections/:section_id/assignments/:assignment_id/submissions/:id', :action => :show

      submissions.put 'courses/:course_id/assignments/:assignment_id/submissions/:id', :action => :update, :path_name => 'course_assignment_submission'
      submissions.put 'sections/:section_id/assignments/:assignment_id/submissions/:id', :action => :update, :path_name => 'section_assignment_submission'
    end

    api.get 'courses/:course_id/assignment_groups', :controller => :assignment_groups, :action => :index, :path_name => 'course_assignment_groups'

    api.with_options(:controller => :discussion_topics) do |topics|
      topics.get 'courses/:course_id/discussion_topics', :action => :index, :path_name => 'course_discussion_topics'
      topics.get 'groups/:group_id/discussion_topics', :action => :index, :path_name => 'group_discussion_topics'
    end

    api.with_options(:controller => :discussion_topics_api) do |topics|
      topics.post 'courses/:course_id/discussion_topics/:topic_id/entries', :action => :add_entry, :path_name => 'course_discussion_add_entry'
      topics.post 'groups/:group_id/discussion_topics/:topic_id/entries', :action => :add_entry, :path_name => 'group_discussion_add_entry'
      topics.get 'courses/:course_id/discussion_topics/:topic_id/entries', :action => :entries, :path_name => 'course_discussion_entries'
      topics.get 'groups/:group_id/discussion_topics/:topic_id/entries', :action => :entries, :path_name => 'group_discussion_entries'
      topics.post 'courses/:course_id/discussion_topics/:topic_id/entries/:entry_id/replies', :action => :add_reply, :path_name => 'course_discussion_add_reply'
      topics.post 'groups/:group_id/discussion_topics/:topic_id/entries/:entry_id/replies', :action => :add_reply, :path_name => 'group_discussion_add_reply'
      topics.get 'courses/:course_id/discussion_topics/:topic_id/entries/:entry_id/replies', :action => :replies, :path_name => 'course_discussion_replies'
      topics.get 'groups/:group_id/discussion_topics/:topic_id/entries/:entry_id/replies', :action => :replies, :path_name => 'group_discussion_replies'
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

    api.with_options(:controller => :sis_imports_api) do |sis|
      sis.post 'accounts/:account_id/sis_imports', :action => :create
      sis.get 'accounts/:account_id/sis_imports/:id', :action => :show
    end

    api.with_options(:controller => :users) do |users|
      users.get 'users/self/activity_stream', :action => :activity_stream
      users.get 'users/activity_stream', :action => :activity_stream # deprecated

      users.get 'users/self/todo', :action => :todo_items
      users.delete 'users/self/todo/:asset_string/:purpose', :action => :ignore_item, :path_name => 'users_todo_ignore'
      users.post 'accounts/:account_id/users', :action => :create
    end

    api.with_options(:controller => :accounts) do |accounts|
      accounts.get 'accounts', :action => :index, :path_name => :accounts
      accounts.get 'accounts/:id', :action => :show
      accounts.get 'accounts/:account_id/courses', :action => :courses_api, :path_name => 'account_courses'
    end

    api.with_options(:controller => :role_overrides) do |roles|
      roles.post 'accounts/:account_id/roles', :action => :add_role
    end

    api.with_options(:controller => :admins) do |admins|
      admins.post 'accounts/:account_id/admins', :action => :create
    end

    api.with_options(:controller => :account_authorization_configs) do |authorization_configs|
      authorization_configs.post 'accounts/:account_id/account_authorization_configs', :action => 'update_all'
    end

    api.get 'users/:user_id/page_views', :controller => :page_views, :action => :index, :path_name => 'user_page_views'
    api.get 'users/:user_id/profile', :controller => :profile, :action => :show

    api.with_options(:controller => :conversations) do |conversations|
      conversations.get 'conversations', :action => :index
      conversations.post 'conversations', :action => :create
      conversations.get 'conversations/find_recipients', :action => :find_recipients
      conversations.post 'conversations/mark_all_as_read', :action => :mark_all_as_read
      conversations.get 'conversations/:id', :action => :show
      conversations.put 'conversations/:id', :action => :update # labels, subscribed-ness, workflow_state
      conversations.delete 'conversations/:id', :action => :destroy
      conversations.post 'conversations/:id/add_message', :action => :add_message
      conversations.post 'conversations/:id/add_recipients', :action => :add_recipients
      conversations.post 'conversations/:id/remove_messages', :action => :remove_messages
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

    api.with_options(:controller => :appointment_groups) do |groups|
      groups.get 'appointment_groups', :action => :index, :path_name => 'appointment_groups'
      groups.post 'appointment_groups', :action => :create
      groups.get 'appointment_groups/:id', :action => :show, :path_name => 'appointment_group'
      groups.put 'appointment_groups/:id', :action => :update
      groups.delete 'appointment_groups/:id', :action => :destroy
    end
  end

  map.oauth2_auth 'login/oauth2/auth', :controller => 'pseudonym_sessions', :action => 'oauth2_auth', :conditions => { :method => :get }
  map.oauth2_token 'login/oauth2/token',:controller => 'pseudonym_sessions', :action => 'oauth2_token', :conditions => { :method => :post }

  ApiRouteSet.route(map, "/api/lti/v1") do |lti|
    lti.post "tools/:tool_id/grade_passback", :controller => :lti_api, :action => :grade_passback, :path_name => "lti_grade_passback_api"
    lti.post "tools/:tool_id/ext_grade_passback", :controller => :lti_api, :action => :legacy_grade_passback, :path_name => "blti_legacy_grade_passback_api"
  end

  map.resources :equation_images, :only => :show

  # assignments at the top level (without a context) -- we have some specs that
  # assert these routes exist, but just 404. I'm not sure we ever actually want
  # top-level assignments available, maybe we should change the specs instead.
  map.resources :assignments, :only => %w(index show)

  map.resources :files do |file|
    file.download 'download', :controller => 'files', :action => 'show', :download => '1'
  end

  map.resources :rubrics do |rubric|
    rubric.resources :rubric_assessments, :as => 'assessments'
  end
  map.global_outcomes 'outcomes', :controller => 'outcomes', :action => 'global_outcomes'
  map.selection_test 'selection_test', :controller => 'external_content', :action => 'selection_test'

  # See how all your routes lay out with "rake routes"
end
