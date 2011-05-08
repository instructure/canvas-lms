ActionController::Routing::Routes.draw do |map|
  
  map.resources :submission_comments, :only => :destroy
  map.resources :email_lists, :only => :create

  map.mark_inbox_as_read 'inbox', :controller => 'context', :action => 'mark_inbox_as_read', :conditions => {:method => :delete}
  map.inbox 'inbox', :controller => 'context', :action => 'inbox'
  map.destroy_inbox_item 'inbox/:id', :controller => 'context', :action => 'destroy_inbox_item', :conditions => {:method => :delete}
  map.inbox_item 'inbox/:id', :controller => 'context', :action => 'inbox_item'
  map.context_message_reply 'messages/:id/reply', :controller => 'context', :action => 'context_message_reply'
  
  # So, this will look like:
  # http://instructure.com/pseudonyms/3/register/5R32s9iqwLK75Jbbj0
  map.registration_confirmation 'pseudonyms/:id/register/:nonce', 
    :controller => 'pseudonyms', :action => 'registration_confirmation'
  map.claim_pseudonym 'pseudonyms/:id/claim/:nonce',
    :controller => 'pseudonyms', :action => 'claim_pseudonym'
  map.re_send_confirmation 'confirmations/:user_id/re_send/:id',
    :controller => 'pseudonyms', :action => 're_send_confirmation'
  map.forgot_password "forgot_password",
    :controller => 'pseudonyms', :action => 'forgot_password'
  map.confirm_change_password "pseudonyms/:pseudonym_id/change_password/:nonce",
    :controller => 'pseudonyms', :action => 'confirm_change_password', :conditions => {:method => :get}
  map.change_password "pseudonyms/:pseudonym_id/change_password/:nonce",
    :controller => 'pseudonyms', :action => 'change_password', :conditions => {:method => :post}
    
  # callback urls for oauth authorization processes
  map.oauth "oauth", :controller => "users", :action => "oauth"
  map.oauth_success "oauth_success", :controller => "users", :action => "oauth_success"
  map.resources :files do |file|
    file.download 'download', :controller => 'files', :action => 'show', :download => '1'
  end

  # assignments at the top level (without a context) -- we have some specs that
  # assert these routes exist, but just 404. I'm not sure we ever actually want
  # top-level assignments available, maybe we should change the specs instead.
  map.resources :assignments, :only => %w(index show)

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
    course.students 'students', :controller => 'courses', :action => 'students'
    course.resources :role_overrides, :only => [:index, :create]
    course.enrollment_invitation 'enrollment_invitation', :controller => 'courses', :action => 'enrollment_invitation'
    course.users 'users', :controller => 'context', :action => 'roster'
    course.user_services 'user_services', :controller => 'context', :action => 'roster_user_services'
    course.user_usage 'users/:user_id/usage', :controller => 'context', :action => 'roster_user_usage'
    course.statistics 'statistics', :controller => 'courses', :action => 'statistics'
    course.prior_users 'users/prior', :controller => 'context', :action => 'prior_users'
    course.user 'users/:id', :controller => 'context', :action => 'roster_user', :conditions => {:method => :get}
    course.roster_messages 'messages', :controller => 'context', :action => 'create_roster_message', :conditions => {:method => :post}
    course.formatted_roster_messages 'messages.:format', :controller => 'context', :action => 'create_roster_message', :conditions => {:method => :post}
    course.message_recipients 'messages/recipients', :controller => 'context', :action => 'recipients'
    course.roster_message 'messages/:id', :controller => 'context', :action => 'read_roster_message', :conditions => {:method => :put}
    course.roster_message_attachment 'messages/:message_id/files/:id', :controller => 'context', :action => 'roster_message_attachment'
    course.unenroll 'unenroll/:id', :controller => 'courses', :action => 'unenroll_user', :conditions => {:method => :delete}
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
    course.details 'details', :controller => 'courses', :action => 'course_details'
    course.re_send_invitations 're_send_invitations', :controller => 'courses', :action => 're_send_invitations', :conditions => {:method => :post}
    course.enroll_users 'enroll_users', :controller => 'courses', :action => 'enroll_users'
    course.link_enrollment 'link_enrollment', :controller => 'courses', :action => 'link_enrollment'
    course.update_nav 'update_nav', :controller => 'courses', :action => 'update_nav'
    course.formatted_enroll_users 'enroll_users.:format', :controller => 'courses', :action => 'enroll_users'
    course.resource :gradebook, :collection => {
      :blank_submission => :get,
      :speed_grader => :get,
      :update_submission => :post,
      :history => :get
    } do |gradebook|
      gradebook.submissions_upload 'submissions_upload/:assignment_id', :controller => 'gradebooks', :action => 'submissions_zip_upload', :conditions => { :method => :post }
    end
    course.attendance 'attendance', :controller => 'gradebooks', :action => 'attendance'
    course.attendance_user 'attendance/:user_id', :controller => 'gradebooks', :action => 'attendance'
    course.imports 'imports', :controller => 'content_imports', :action => 'intro'
    course.resources :zip_file_imports, :only => [:new, :create], :collection => [:import_status]
    course.import_files 'imports/files', :controller => 'content_imports', :action => 'files'
    course.import_quizzes 'imports/quizzes', :controller => 'content_imports', :action => 'quizzes'
    course.import_content 'imports/content', :controller => 'content_imports', :action => 'content'
    course.import_copy 'imports/copy', :controller => 'content_imports', :action => 'copy_course', :conditions => {:method => :get}
    course.import_migrate 'imports/migrate', :controller => 'content_imports', :action => 'migrate_content'
    course.import_copy_content 'imports/copy', :controller => 'content_imports', :action => 'copy_course_content', :conditions => {:method => :post}
    course.import_migrate_choose 'imports/migrate/:id', :controller => 'content_imports', :action => 'migrate_content_choose'
    course.import_migrate_execute 'imports/migrate/:id/execute', :controller => 'content_imports', :action => 'migrate_content_execute'
    course.import_review 'imports/review', :controller => 'content_imports', :action => 'review'
    course.import_list 'imports/list', :controller => 'content_imports', :action => 'index'
    course.resource :gradebook_upload
    course.resources :notifications, :only => [:index, :destroy, :update], :collection => {:clear => :post}
    course.grades "grades", :controller => 'gradebooks', :action => 'grade_summary', :id => nil
    course.grading_standards "grading_standards", :controller => 'gradebooks', :action => 'grading_standards', :conditions => {:method => :get}
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
    end
    course.resources :grading_standards, :only => %w(create update)
    course.resources :assignment_groups, :collection => {:reorder => :post} do |group|
      group.reorder_assignments 'reorder', :controller => 'assignment_groups', :action => 'reorder_assignments'
    end
    course.resources :external_tools, :only => [:create, :update, :destroy, :index] do |tools|
      tools.finished 'finished', :controller => 'external_tools', :action => 'finished'
    end
    course.resources :submissions
    course.resources :calendar_events
    course.resources :chats
    course.resources :files, :collection => {:quota => :get, :reorder => :post, :list => :get} do |file|
      file.text_inline 'inline', :controller => 'files', :action => 'text_show'
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
      file.typed_download 'download.:type', :controller => 'files', :action => 'show', :download => '1'
      file.preview 'preview', :controller => 'files', :action => 'show', :preview => '1'
      file.inline_view 'inline_view', :controller => 'files', :action => 'show', :inline => '1'
      file.attachment_content 'contents', :controller => 'files', :action => 'attachment_content'
      file.relative_path ":file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    end
    course.relative_file_path "file_contents/:file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    course.resources :folders do |folder|
      folder.download 'download', :controller => 'folders', :action => 'download'
    end
    course.resources :groups, :collection => {:create_category => :post, :delete_category => :delete}
    course.resources :wiki_pages, :as => 'wiki' do |wiki_page|
      wiki_page.latest_version_number 'revisions/latest', :controller => 'wiki_page_revisions', :action => 'latest_version_number'
      wiki_page.resources :wiki_page_revisions, :as => "revisions"
      wiki_page.resources :wiki_page_comments, :as => "comments"
    end
    course.named_wiki_page 'wiki/:id', :id => /[^\/]+/, :controller => 'wiki_pages', :action => 'show'
    course.resources :conferences do |conference|
      conference.join "join", :controller => "conferences", :action => "join"
    end
    
    course.resources :question_banks do |bank|
      bank.bookmark 'bookmark', :controller => 'question_banks', :action => 'bookmark'
      bank.reorder 'reorder', :controller => 'question_banks', :action => 'reorder'
      bank.questions 'questions', :controller => 'question_banks', :action => 'questions'
      bank.move_questions 'move_questions', :controller => 'question_banks', :action => 'move_questions'
    end
    course.resources :assessment_questions do |question|
      question.move_question 'move', :controller => 'assessment_questions', :action => 'move'
    end
    course.quizzes_publish 'quizzes/publish', :controller => 'quizzes', :action => 'publish'
    course.resources :quizzes do |quiz|
      quiz.reorder "reorder", :controller => "quizzes", :action => "reorder"
      quiz.history "history", :controller => "quizzes", :action => "history"
      quiz.statistics "statistics", :controller => 'quizzes', :action => 'statistics'
      quiz.formatted_statistics "statistics.:format", :controller => 'quizzes', :action => 'statistics'
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
    course.user_notes 'user_notes', :controller => 'user_notes', :action => 'user_notes'
    course.switch_role 'switch_role/:role', :controller => 'courses', :action => 'switch_role'
    course.sis_publish_status 'details/sis_publish', :controller => 'courses', :action => 'sis_publish_status', :conditions => {:method => :get}
    course.publish_to_sis 'details/sis_publish', :controller => 'courses', :action => 'publish_to_sis', :conditions => {:method => :post}
  end

  map.resources :rubrics do |rubric|
    rubric.resources :rubric_assessments, :as => 'assessments'
  end
  map.global_outcomes 'outcomes', :controller => 'outcomes', :action => 'global_outcomes'

  map.resources :page_views, :only => [:update,:index]
  map.create_media_object 'media_objects', :controller => 'context', :action => 'create_media_object', :conditions => {:method => :post}
  map.kaltura_notifications 'media_objects/kaltura_notifications', :controller => 'context', :action => 'kaltura_notifications'
  map.media_object 'media_objects/:id', :controller => 'context', :action => 'media_object_inline'
  map.media_object_redirect 'media_objects/:id/redirect', :controller => 'context', :action => 'media_object_redirect'
  map.page_views 'info/page_views', :controller => 'info', :action => 'page_views'
  map.external_content_success 'external_content/success/:service', :controller => 'external_content', :action => 'success'
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
    group.roster_messages 'messages', :controller => 'context', :action => 'create_roster_message', :conditions => {:method => :post}
    group.formatted_roster_messages 'messages.:format', :controller => 'context', :action => 'create_roster_message', :conditions => {:method => :post}
    group.message_recipients 'messages/recipients', :controller => 'context', :action => 'recipients'
    group.roster_message 'messages/:id', :controller => 'context', :action => 'resend_roster_message', :conditions => {:method => :put}
    group.roster_message_attachment 'messages/:message_id/files/:id', :controller => 'context', :action => 'roster_message_attachment'
    group.remove_user 'remove_user/:id', :controller => 'groups', :action => 'remove_user', :conditions => {:method => :delete}
    group.add_user 'add_user', :controller => 'groups', :action => 'add_user'
    group.members 'members.:format', :controller => 'groups', :action => 'context_group_members', :conditions => {:method => :get}
    group.members 'members', :controller => 'groups', :action => 'context_group_members', :conditions => {:method => :get}
    group.resources :notifications, :only => [:index, :destroy, :update], :collection => {:clear => :post}
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
    group.resources :files, :collection => {:quota => :get, :reorder => :post, :list => :get} do |file|
      file.text_inline 'inline', :controller => 'files', :action => 'text_show'
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
      file.typed_download 'download.:type', :controller => 'files', :action => 'show', :download => '1'
      file.preview 'preview', :controller => 'files', :action => 'show', :preview => '1'
      file.inline_view 'inline_view', :controller => 'files', :action => 'show', :inline => '1'
      file.attachment_content 'contents', :controller => 'files', :action => 'attachment_content'
      file.relative_path ":file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    end
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
    
    account.statistics 'statistics', :controller => 'accounts', :action => 'statistics'
    account.statistics_page_views 'statistics/page_views', :controller => 'accounts', :action => 'statistics_page_views'
    account.statistics_graph 'statistics/over_time/:attribute', :controller => 'accounts', :action => 'statistics_graph'
    account.formatted_statistics_graph 'statistics/over_time/:attribute.:format', :controller => 'accounts', :action => 'statistics_graph'
    account.turnitin_confirmation 'turnitin/:id/:shared_secret', :controller => 'accounts', :action => 'turnitin_confirmation'
    account.resources :role_overrides, :only => [:index, :create], :collection => {:add_role => :post, :remove_role => :delete}
    account.resources :terms
    account.resources :sub_accounts
    account.avatars 'avatars', :controller => 'accounts', :action => 'avatars'
    account.sis_import 'sis_import', :controller => 'accounts', :action => 'sis_import'
    account.sis_import_submit 'sis_import_submit', :controller => 'accounts', :action => 'sis_import_submit'
    account.add_user 'users', :controller => 'accounts', :action => 'add_user', :conditions => {:method => :post}
    account.confirm_delete_user 'users/:user_id/delete', :controller => 'accounts', :action => 'confirm_delete_user'
    account.delete_user 'users/:user_id', :controller => 'accounts', :action => 'remove_user', :conditions => {:method => :delete}
    account.resources :users
    account.resources :account_notifications, :only => [:create, :destroy]
    account.resources :announcements
    account.resources :assignments
    account.resources :submissions
    account.resource :account_authorization_config
    account.resources :external_tools, :only => [:create, :update, :destroy, :index] do |tools|
      tools.finished 'finished', :controller => 'external_tools', :action => 'finished'
    end
    account.resources :chats
    account.user_outcomes_results 'outcomes/users/:user_id', :controller => 'outcomes', :action => 'user_outcome_results'
    account.resources :outcomes, :collection => {:list => :get, :add_outcome => :post} do |outcome|
      outcome.results 'results', :controller => 'outcomes', :action => 'outcome_results'
      outcome.result 'results/:id', :controller => 'outcomes', :action => 'outcome_result'
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
    account.resources :groups, :collection => {:create_category => :post, :delete_category => :delete}
    account.resources :outcomes
    account.group_unassigned_members 'group_unassigned_members', :controller => 'groups', :action => 'unassigned_members', :conditions => { :method => :get }
    account.group_unassigned_members 'group_unassigned_members.:format', :controller => 'groups', :action => 'unassigned_members', :conditions => { :method => :get }
    account.courses 'courses', :controller => 'accounts', :action => 'courses'
    account.courses_formatted 'courses.:format', :controller => 'accounts', :action => 'courses'
    account.courses_redirect 'courses/:id', :controller => 'accounts', :action => 'courses_redirect'
    account.user_notes 'user_notes', :controller => 'user_notes', :action => 'user_notes'
    account.run_report 'run_report', :controller => 'accounts', :action => 'run_report'
  end
  map.avatar_image 'images/users/:user_id', :controller => 'info', :action => 'avatar_image_url', :conditions => {:method => :get}
  map.thumbnail_image 'images/thumbnails/:id/:uuid', :controller => 'files', :action => 'image_thumbnail'
  map.show_thumbnail_image 'images/thumbnails/show/:id/:uuid', :controller => 'files', :action => 'show_thumbnail'
  map.report_avatar_image 'images/users/:user_id/report', :controller => 'users', :action => 'report_avatar_image', :conditions => {:method => :post}
  map.update_avatar_image 'images/users/:user_id', :controller => 'users', :action => 'update_avatar_image', :conditions => {:method => :put}
  map.resources :account_authorization_configs
  
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
  map.image_search 'search/images', :controller => 'users', :action => 'image_search'
  map.search_rubrics 'search/rubrics', :controller => "search", :action => "rubrics"
  map.resources :users do |user|
    user.delete 'delete', :controller => 'users', :action => 'delete'
    user.resources :files, :collection => {:quota => :get, :reorder => :post, :list => :get} do |file|
      file.text_inline 'inline', :controller => 'files', :action => 'text_show'
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
      file.typed_download 'download.:type', :controller => 'files', :action => 'show', :download => '1'
      file.preview 'preview', :controller => 'files', :action => 'show', :preview => '1'
      file.inline_view 'inline_view', :controller => 'files', :action => 'show', :inline => '1'
      file.attachment_content 'contents', :controller => 'files', :action => 'attachment_content'
      file.relative_path ":file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    end
    user.resources :page_views, :only => [:index]
    user.resources :folders do |folder|
      folder.download 'download', :controller => 'folders', :action => 'download'
    end
    user.resources :calendar_events
    user.resources :notifications, :only => [:destroy, :update], :collection => {:clear => :post}
    user.resources :rubrics
    user.resources :rubric_associations do |association|
      association.invite_assessor "invite", :controller => "rubric_assessments", :action => "invite"
      association.resources :rubric_assessments, :as => 'assessments'
    end
    user.resources :pseudonyms
    user.resources :question_banks, :only => [:index]
    user.assignments_needing_grading 'assignments_needing_grading', :controller => 'users', :action => 'assignments_needing_grading'
    user.assignments_needing_submitting 'assignments_needing_submitting', :controller => 'users', :action => 'assignments_needing_submitting'
    user.sent_messages 'messages/sent', :controller => 'users', :action => 'sent_messages'
    user.admin_merge 'admin_merge', :controller => 'users', :action => 'admin_merge', :conditions => {:method => :get}
    user.confirm_merge 'merge', :controller => 'users', :action => 'confirm_merge', :conditions => {:method => :get}
    user.merge 'merge', :controller => 'users', :action => 'merge', :conditions => {:method => :post}
    user.grades 'grades', :controller => 'users', :action => 'grades'
    user.resources :user_notes
    user.courses 'courses', :controller => 'users', :action => 'courses'
    user.outcomes 'outcomes', :controller => 'outcomes', :action => 'user_outcome_results'
    user.resources :zip_file_imports, :only => [:new, :create], :collection => [:import_status]
    user.resources :files, :collection => {:quota => :get, :reorder => :post, :list => :get} do |file|
      file.text_inline 'inline', :controller => 'files', :action => 'text_show'
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
      file.preview 'preview', :controller => 'files', :action => 'show', :preview => '1'
      file.inline_view 'inline_view', :controller => 'files', :action => 'show', :inline => '1'
      file.attachment_content 'contents', :controller => 'files', :action => 'attachment_content'
      file.relative_path ":file_path", :file_path => /.+/, :controller => 'files', :action => 'show_relative'
    end
  end
  map.resource :profile, :only => [:show, :update], :controller => "profile", :member => { :communication => :get, :update_communication => :post } do |profile|
    profile.resources :pseudonyms, :except => %w(index)
    profile.pics 'profile_pictures', :controller => 'profile', :action => 'profile_pics'
    profile.user_service "user_services/:id", :controller => "users", :action => "delete_user_service", :conditions => {:method => :delete}
    profile.create_user_service "user_services", :controller => "users", :action => "create_user_service", :conditions => {:method => :post}
  end
  map.resources :communication_channels, :collection => {:try_merge => :post} do |channel|
    channel.merge "merge/:code", :controller => "communication_channels", :action => "merge"
    channel.confirm "confirm/:nonce", :controller => 'communication_channels', :action => 'confirm'

  end
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
    dashboard.resources :notifications, :only => [:index, :destroy, :update]
    dashboard.eportfolios "eportfolios", :controller => "eportfolios", :action => "user_index"
    dashboard.grades "grades", :controller => "users", :action => "grades"
    dashboard.resources :rubrics, :as => :assessments
    dashboard.comment_session "comment_session", :controller => "users", :action => "kaltura_session"
    dashboard.ignore_item 'ignore_item/:asset_string/:purpose', :controller => 'users', :action => 'ignore_item', :conditions => {:method => :delete}
  end
  map.dashboard_ignore_channel 'dashboard/ignore_path', :controller => "users", :action => "ignore_channel", :conditions => {:method => :post}

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
    
  # Need to check if these routes are even necessary, since the
  # controller/action map is still enabled.
  map.get_web_screenshot 'processors/webshots', :controller => 'processors', :action => 'get_web_screenshot', :conditions => { :method => :get }
  map.update_web_screenshot 'processors/webshots/:id', :controller => 'processors', :action => 'update_web_screenshot', :conditions => { :method => :post }
  map.retrieve_external_feed 'processors/external_feeds', :controller => 'processors', :action => 'retrieve_external_feed', :conditions => { :method => :get }
  map.retrieve_twitter_search 'processors/twitter_searches', :controller => 'processors', :action => 'retrieve_twitter_search', :conditions => { :method => :get }
  map.retrieve_twitter_user_results 'processors/twitter_users', :controller => 'processors', :action => 'retrieve_twitter_user_results', :conditions => { :method => :get }

  map.calendar 'calendar', :controller => 'calendars', :action => 'show', :conditions => { :method => :get }
  map.files 'files', :controller => 'files', :action => 'full_index', :conditions => { :method => :get }
  map.s3_success 'files/s3_success/:id', :controller => 'files', :action => 's3_success'
  map.public_url 'files/:id/public_url.:format', :controller => 'files', :action => 'public_url'
  map.file_create_pending 'files/pending', :controller=> 'files', :action => 'create_pending'
  map.assignments 'assignments', :controller => 'assignments', :action => 'index', :conditions => { :method => :get }

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
  map.resources :errors, :as => :error_reports, :only => [:show, :index]
  
  map.health_check "health_check", :controller => 'info', :action => 'health_check'
  
  map.facebook "facebook", :controller => "facebook", :action => "index"
  map.facebook_hide_message "facebook/message/:id", :controller => "facebook", :action => "hide_message"
  map.facebook_settings "facebook/settings", :controller => "facebook", :action => "settings"
  map.facebook_notification_preferences "facebook/notification_preferences", :controller => "facebook", :action => "notification_preferences"
  
  map.resources :interaction_tests, :collection => {:next => :get, :register => :get, :groups => :post}
  
  map.resources :delayed_jobs, :member => {:update => :put, :queue => :put, :hold => :put}, :collection => {:hold => :put, :queue => :put}
  map.object_snippet 'object_snippet/:context_code/:asset_string/:key', :controller => 'context', :action => 'context_object'
  map.saml_consume "saml_consume", :controller => "pseudonym_sessions", :action => "saml_consume" 
  map.saml_logout "saml_logout", :controller => "pseudonym_sessions", :action => "saml_logout" 
  map.saml_meta_data "saml_meta_data", :controller => 'accounts', :action => 'saml_meta_data'
  
  # Routes for course exports
  map.connect 'xsd/:version.xsd', :controller => 'content_exports', :action => 'xml_schema'
  map.resources :content_exports do |ce|
    ce.resources :files do |file|
      file.download 'download', :controller => 'files', :action => 'show', :download => '1'
    end
  end
  
  Jammit::Routes.draw(map)

  # API routes
  ApiRouteSet.new(map, "/api/v1") do |api|
    api.resources :courses,
                  :name_prefix => "api_v1_",
                  :only => %w(index) do |course|
      course.students 'students.:format',
        :controller => 'courses', :action => 'students',
        :conditions => { :method => :get }
      course.sections 'sections.:format',
        :controller => 'courses', :action => 'sections',
        :conditions => { :method => :get }
      course.resources :assignments,
                        :controller => 'assignments_api',
                        :only => %w(show index create update) do |assignment|
        assignment.resources :submissions,
                        :controller => 'submissions_api',
                        :only => %w(index show update)
      end
      course.resources :assignment_groups,
                        :only => %w(index)
      course.student_submissions 'students/submissions.:format',
        :controller => 'submissions_api', :action => 'for_students',
        :conditions => { :method => :get }
    end
    api.resources :accounts, :only => %{} do |account|
      account.resources :sis_imports,
                        :controller => 'sis_imports_api',
                        :only => %w(show create)
    end
  end

  # See how all your routes lay out with "rake routes"
end
