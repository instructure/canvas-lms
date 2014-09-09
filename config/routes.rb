full_path_glob = '(/*full_path)'

# allow plugins to prepend routes
Dir["vendor/plugins/*/config/pre_routes.rb"].each { |pre_routes|
  load pre_routes
}

CanvasRails::Application.routes.draw do
  resources :submission_comments, :only => :destroy

  match 'inbox' => 'context#inbox', :as => :inbox

  match 'conversations/unread' => 'conversations#index', :as => :conversations_unread, :redirect_scope => 'unread'
  match 'conversations/starred' => 'conversations#index', :as => :conversations_starred, :redirect_scope => 'starred'
  match 'conversations/sent' => 'conversations#index', :as => :conversations_sent, :redirect_scope => 'sent'
  match 'conversations/archived' => 'conversations#index', :as => :conversations_archived, :redirect_scope => 'archived'
  match 'conversations/find_recipients' => 'search#recipients'

  match 'search/recipients' => 'search#recipients', :as => :search_recipients
  match 'conversations/mark_all_as_read' => 'conversations#mark_all_as_read', :as => :conversations_mark_all_as_read, :via => :post
  match 'conversations/watched_intro' => 'conversations#watched_intro', :as => :conversations_watched_intro, :via => :post
  match 'conversations/batches' => 'conversations#batches', :as => :conversation_batches
  match 'conversations/toggle_new_conversations' => 'conversations#toggle_new_conversations', :as => :toggle_new_conversations, :via => :post
  resources :conversations, :only => [:index, :show, :update, :create, :destroy] do
    match 'add_recipients' => 'conversations#add_recipients', :as => :add_recipients, :via => :post
    match 'add_message' => 'conversations#add_message', :as => :add_message, :via => :post
    match 'remove_messages' => 'conversations#remove_messages', :as => :remove_messages, :via => :post
  end

  # So, this will look like:
  # http://instructure.com/register/5R32s9iqwLK75Jbbj0
  match 'register/:nonce' => 'communication_channels#confirm', :as => :registration_confirmation
  # deprecated
  match 'pseudonyms/:id/register/:nonce' => 'communication_channels#confirm', :as => :registration_confirmation_deprecated
  match 'confirmations/:user_id/re_send(/:id)' => 'communication_channels#re_send_confirmation', :as => :re_send_confirmation, :id => nil
  match 'forgot_password' => 'pseudonyms#forgot_password', :as => :forgot_password
  match 'pseudonyms/:pseudonym_id/change_password/:nonce' => 'pseudonyms#confirm_change_password', :as => :confirm_change_password, :via => :get
  match 'pseudonyms/:pseudonym_id/change_password/:nonce' => 'pseudonyms#change_password', :as => :change_password, :via => :post

  # callback urls for oauth authorization processes
  match 'oauth' => 'users#oauth', :as => :oauth
  match 'oauth_success' => 'users#oauth_success', :as => :oauth_success

  match 'mr/:id' => 'info#message_redirect', :as => :message_redirect
  match 'help_links' => 'info#help_links', :as => :help_links

  concern :question_banks do
    resources :question_banks do
      match 'bookmark' => 'question_banks#bookmark', :as => :bookmark
      match 'reorder' => 'question_banks#reorder', :as => :reorder
      match 'questions' => 'question_banks#questions', :as => :questions
      match 'move_questions' => 'question_banks#move_questions', :as => :move_questions
      resources :assessment_questions
    end
  end

  concern :groups do
    resources :groups
    resources :group_categories, :only => [:create, :update, :destroy]
    match 'group_unassigned_members' => 'groups#unassigned_members', :as => :group_unassigned_members, :via => :get
  end

  concern :files do
    resources :files do
      match 'inline' => 'files#text_show', :as => :text_inline
      match 'download' => 'files#show', :as => :download, :download => '1'
      match 'download.:type' => 'files#show', :as => :typed_download, :download => '1'
      match 'preview' => 'files#show', :as => :preview, :preview => '1'
      match 'inline_view' => 'files#show', :as => :inline_view, :inline => '1'
      match 'contents' => 'files#attachment_content', :as => :attachment_content
      collection do
        get "folder#{full_path_glob}", :controller => :files, :action => :ember_app, :format => false
        get "search", :controller => :files, :action => :ember_app, :format => false
        get :quota
        post :reorder
      end
      match ':file_path' => 'files#show_relative', :as => :relative_path, :file_path => /.+/ #needs to stay below ember_app route
    end
  end

  concern :file_images do
    match 'images' => 'files#images', :as => :images
  end

  concern :relative_files do
    match 'file_contents/:file_path' => 'files#show_relative', :as => :relative_file_path, :file_path => /.+/
  end

  concern :folders do
    resources :folders do
      match 'download' => 'folders#download', :as => :download
    end
  end

  concern :media do
    match 'media_download' => 'users#media_download', :as => :media_download
    match 'media_download.:type' => 'users#media_download', :as => :typed_media_download
  end

  concern :users do
    match 'users' => 'context#roster', :as => :users
    match 'user_services' => 'context#roster_user_services', :as => :user_services
    match 'users/:user_id/usage' => 'context#roster_user_usage', :as => :user_usage
    match 'users/:id' => 'context#roster_user', :as => :user, :via => :get
  end

  concern :announcements do
    resources :announcements
    match 'announcements/external_feeds' => 'announcements#create_external_feed', :as => :announcements_external_feeds, :via => :post
    match 'announcements/external_feeds/:id' => 'announcements#destroy_external_feed', :as => :announcements_external_feed, :via => :delete
  end

  concern :discussions do
    resources :discussion_topics, :only => [:index, :new, :show, :edit, :destroy]
    match 'discussion_topics/:id/:extras' => 'discussion_topics#show', :as => :map, :extras => /.+/
    resources :discussion_entries
  end

  concern :wikis do
    ####
    ## Leaving these routes here for when we need them later :)
    ##
    ## Aside from the /wiki route itself, all new routes will be /pages. The /wiki route will be reused to redirect
    ## the user to the wiki front page, if configured, or the wiki page list otherwise.
    ####
    # match 'wiki' => 'wiki_pages#front_page', :via => :get, :as => :wiki

    ####
    ## Placing these routes above the /wiki routes below will cause the helper functions to generate urls and paths
    ## pointing to /pages rather than the legacy /wiki.
    ####
    # resources :wiki_pages, :path => :pages do
    #   match 'revisions/latest' => 'wiki_page_revisions#latest_version_number', :as => :latest_version_number
    #   resources :wiki_page_revisions, :as => "revisions"
    # end
    #
    ####
    ## We'll just do specific routes below until we can swap /pages and /wiki completely.
    ####
    get 'pages' => 'wiki_pages#pages_index'
    get 'pages/:wiki_page_id' => 'wiki_pages#show_page', :wiki_page_id => /[^\/]+/, :as => :named_page
    get 'pages/:wiki_page_id/edit' => 'wiki_pages#edit_page', :wiki_page_id => /[^\/]+/, :as => :edit_named_page
    get 'pages/:wiki_page_id/revisions' => 'wiki_pages#page_revisions', :wiki_page_id => /[^\/]+/, :as => :named_page_revisions

    resources :wiki_pages, :path => :wiki do
      match 'revisions/latest' => 'wiki_page_revisions#latest_version_number', :as => :latest_version_number
      resources :wiki_page_revisions, :path => :revisions
    end

    ####
    ## This will cause the helper functions to generate /pages urls, but will still allow /wiki routes to work properly
    ####
    #match 'pages/:id' => 'wiki_pages#show', :id => /[^\/]+/, :as => :named_wiki_page

    match 'wiki/:id' => 'wiki_pages#show', :as => :named_wiki_page, :id => /[^\/]+/
  end

  concern :conferences do
    resources :conferences do
      match 'join' => 'conferences#join', :as => :join
      match 'close' => 'conferences#close', :as => :close
      match 'settings' => 'conferences#settings', :as => :settings
    end
  end

  concern :zip_file_imports do
    resources :zip_file_imports, :only => [:new, :create, :show]
    match 'imports/files' => 'content_imports#files', :as => :import_files
  end

  # There are a lot of resources that are all scoped to the course level
  # (assignments, files, wiki pages, user lists, forums, etc.).  Many of
  # these resources also apply to groups and individual users.  We call
  # courses, users, groups, or even accounts in this setting, "contexts".
  # There are some helper methods like the before_filter :get_context in application_controller
  # and the application_helper method :context_url to make retrieving
  # these contexts, and also generating context-specific urls, easier.
  resources :courses do
    # DEPRECATED
    match 'self_enrollment/:self_enrollment' => 'courses#self_enrollment', :as => :self_enrollment, :via => :get
    match 'self_unenrollment/:self_unenrollment' => 'courses#self_unenrollment', :as => :self_unenrollment, :via => :post
    match 'restore' => 'courses#restore', :as => :restore
    match 'backup' => 'courses#backup', :as => :backup
    match 'unconclude' => 'courses#unconclude', :as => :unconclude
    match 'students' => 'courses#students', :as => :students
    match 'enrollment_invitation' => 'courses#enrollment_invitation', :as => :enrollment_invitation
    # this needs to come before the users concern, or users/:id will preempt it
    match 'users/prior' => 'context#prior_users', :as => :prior_users
    concerns :users
    match 'statistics' => 'courses#statistics', :as => :statistics
    match 'unenroll/:id' => 'courses#unenroll_user', :as => :unenroll, :via => :delete
    match 'move_enrollment/:id' => 'courses#move_enrollment', :as => :move_enrollment, :via => :post
    match 'unenroll/:id.:format' => 'courses#unenroll_user', :as => :formatted_unenroll, :via => :delete
    match 'limit_user_grading/:id' => 'courses#limit_user', :as => :limit_user_grading, :via => :post
    match 'conclude_user/:id' => 'courses#conclude_user', :as => :conclude_user_enrollment, :via => :delete
    match 'unconclude_user/:id' => 'courses#unconclude_user', :as => :unconclude_user_enrollment, :via => :post
    resources :sections, :except => ["index", "edit", "new"] do
      match 'crosslist/confirm/:new_course_id' => 'sections#crosslist_check', :as => :confirm_crosslist
      match 'crosslist' => 'sections#crosslist', :as => :crosslist, :via => :post
      match 'crosslist' => 'sections#uncrosslist', :as => :uncrosslist, :via => :delete
    end

    match 'undelete' => 'context#undelete_index', :as => :undelete_items
    match 'undelete/:asset_string' => 'context#undelete_item', :as => :undelete_item
    match 'settings' => 'courses#settings', :as => :settings
    match 'details' => 'courses#settings', :as => :details
    match 're_send_invitations' => 'courses#re_send_invitations', :as => :re_send_invitations, :via => :post
    match 'enroll_users' => 'courses#enroll_users', :as => :enroll_users
    match 'link_enrollment' => 'courses#link_enrollment', :as => :link_enrollment
    match 'update_nav' => 'courses#update_nav', :as => :update_nav
    match 'enroll_users.:format' => 'courses#enroll_users', :as => :formatted_enroll_users
    resource :gradebook do
      match 'submissions_upload/:assignment_id' => 'gradebooks#submissions_zip_upload', :as => :submissions_upload, :via => :post
      collection do
        get :change_gradebook_version
        get :blank_submission
        get :speed_grader
        post :speed_grader_settings
        get :history
        post :update_submission
      end
    end

    match 'gradebook2' => "gradebooks#gradebook2"

    match 'attendance' => 'gradebooks#attendance', :as => :attendance
    match 'attendance/:user_id' => 'gradebooks#attendance', :as => :attendance_user
    concerns :zip_file_imports
    # DEPRECATED old migration emails pointed the user to this url, leave so the controller can redirect
    match 'imports/list' => 'content_imports#index', :as => :import_list
    # DEPRECATED
    match 'imports' => 'content_imports#intro', :as => :imports
    resource :gradebook_upload
    match 'grades' => 'gradebooks#grade_summary', :as => :grades, :id => nil
    match 'grading_rubrics' => 'gradebooks#grading_rubrics', :as => :grading_rubrics
    match 'grades/:id' => 'gradebooks#grade_summary', :as => :student_grades
    concerns :announcements
    match 'calendar' => 'calendars#show', :as => :old_calendar
    match 'locks' => 'courses#locks', :as => :locks
    concerns :discussions
    resources :assignments do
      resources :submissions do
        match 'turnitin/resubmit' => 'submissions#resubmit_to_turnitin', :as => :resubmit_to_turnitin, :via => :post
        match 'turnitin/:asset_string' => 'submissions#turnitin_report', :as => :turnitin_report
      end
      match 'rubric' => 'assignments#rubric', :as => :rubric
      resource :rubric_association, :path => :rubric do
        resources :rubric_assessments, :path => :assessments
      end

      match 'peer_reviews' => 'assignments#peer_reviews', :as => :peer_reviews, :via => :get
      match 'assign_peer_reviews' => 'assignments#assign_peer_reviews', :as => :assign_peer_reviews, :via => :post
      match 'peer_reviews/:id' => 'assignments#delete_peer_review', :as => :delete_peer_review, :via => :delete
      match 'peer_reviews/:id' => 'assignments#remind_peer_review', :as => :remind_peer_review, :via => :post
      match 'peer_reviews/users/:reviewer_id' => 'assignments#assign_peer_review', :as => :assign_peer_review, :via => :post
      match 'mute' => 'assignments#toggle_mute', :as => :mute, :via => :put

      collection do
        get :syllabus
        get :submissions
      end

      member do
        get :list_google_docs
      end
    end

    resources :grading_standards, :only => ["index", "create", "update", "destroy"]
    resources :assignment_groups do
      match 'reorder' => 'assignment_groups#reorder_assignments', :as => :reorder_assignments
      collection do
        post :reorder
      end
    end

    match 'external_tools/sessionless_launch' => 'external_tools#sessionless_launch', :as => :external_tools_sessionless_launch
    resources :external_tools do
      match 'resource_selection' => 'external_tools#resource_selection', :as => :resource_selection
      match 'homework_submission' => 'external_tools#homework_submission', :as => :homework_submission
      match 'finished' => 'external_tools#finished', :as => :finished
      collection do
        get :retrieve
        get :homework_submissions
      end
    end

    get 'lti/basic_lti_launch_request/:message_handler_id', controller: 'lti/message', action: 'basic_lti_launch_request', as: :basic_lti_launch_request
    get 'lti/tool_proxy_registration', controller: 'lti/message', action: 'registration', :as => :tool_proxy_registration


    resources :submissions
    resources :calendar_events

    concerns :files, :file_images, :relative_files, :folders
    concerns :groups
    concerns :wikis
    concerns :conferences
    concerns :question_banks

    match 'quizzes/publish'   => 'quizzes/quizzes#publish',   :as => :quizzes_publish
    match 'quizzes/unpublish' => 'quizzes/quizzes#unpublish', :as => :quizzes_unpublish

    resources :quizzes, controller: 'quizzes/quizzes' do
      match 'managed_quiz_data' => 'quizzes/quizzes#managed_quiz_data', :as => :managed_quiz_data
      match 'submission_versions' => 'quizzes/quizzes#submission_versions', :as => :submission_versions
      match 'history' => 'quizzes/quizzes#history', :as => :history
      match 'statistics' => 'quizzes/quizzes#statistics', :as => :statistics
      match 'statistics_cqs' => 'quizzes/quizzes#statistics_cqs', :as => :statistics_cqs
      match 'read_only' => 'quizzes/quizzes#read_only', :as => :read_only
      match 'submission_html' => 'quizzes/quizzes#submission_html', :as => :submission_html

      resources :quiz_submissions, :controller => 'quizzes/quiz_submissions', :path => :submissions do
        collection do
          put :backup
        end
        member do
          get :record_answer
          post :record_answer
        end
      end

      match 'extensions/:user_id' => 'quizzes/quiz_submissions#extensions', :as => :extensions, :via => :post
      resources :quiz_questions, :controller => 'quizzes/quiz_questions', :path => :questions, :only => ["create", "update", "destroy", "show"]
      resources :quiz_groups, :controller => 'quizzes/quiz_groups', :path => :groups, :only => ["create", "update", "destroy"] do
        member do
          post :reorder
        end
      end

      match 'take' => 'quizzes/quizzes#show', :as => :take, :take => '1'
      match 'take/questions/:question_id' => 'quizzes/quizzes#show', :as => :question, :take => '1'
      match 'moderate' => 'quizzes/quizzes#moderate', :as => :moderate
      match 'lockdown_browser_required' => 'quizzes/quizzes#lockdown_browser_required', :as => :lockdown_browser_required
    end

    resources :collaborations
    resources :gradebook_uploads
    resources :rubrics
    resources :rubric_associations do
      match 'remind/:assessment_request_id' => 'rubric_assessments#remind', :as => :remind_assessee
      resources :rubric_assessments, :path => 'assessments'
    end

    match 'outcomes/users/:user_id' => 'outcomes#user_outcome_results', :as => :user_outcomes_results
    resources :outcomes do
      match 'alignments/reorder' => 'outcomes#reorder_alignments', :as => :reorder_alignments, :via => :post
      match 'alignments/:id' => 'outcomes#alignment_redirect', :as => :alignment_redirect, :via => :get
      match 'alignments' => 'outcomes#align', :as => :align, :via => :post
      match 'alignments/:id' => 'outcomes#remove_alignment', :as => :remove_alignment, :via => :delete
      match 'results' => 'outcomes#outcome_results', :as => :results
      match 'results/:id' => 'outcomes#outcome_result', :as => :result
      match 'details' => 'outcomes#details', :as => :details
      collection do
        get :list
        post :add_outcome
      end
    end

    resources :outcome_groups, :only => ["create", "update", "destroy"] do
      match 'reorder' => 'outcome_groups#reorder', :as => :reorder
    end

    resources :context_modules, :path => :modules do
      match 'items' => 'context_modules#add_item', :as => :add_item, :via => :post
      match 'reorder' => 'context_modules#reorder_items', :as => :reorder, :via => :post
      match 'collapse' => 'context_modules#toggle_collapse', :as => :toggle_collapse
      match 'prerequisites/:code' => 'context_modules#content_tag_prerequisites_needing_finishing', :as => :prerequisites_needing_finishing
      match 'items/last' => 'context_modules#module_redirect', :as => :last_redirect, :last => 1
      match 'items/first' => 'context_modules#module_redirect', :as => :first_redirect, :first => 1
      collection do
        post :reorder
        get :progressions
      end
    end

    resources :content_exports, :only => ["create", "index", "destroy", "show"]
    match 'modules/items/assignment_info' => 'context_modules#content_tag_assignment_data', :as => :context_modules_assignment_info, :via => :get
    match 'modules/items/:id' => 'context_modules#item_redirect', :as => :context_modules_item_redirect, :via => :get
    match 'modules/items/sequence/:id' => 'context_modules#item_details', :as => :context_modules_item_details, :via => :get
    match 'modules/items/:id' => 'context_modules#remove_item', :as => :context_modules_remove_item, :via => :delete
    match 'modules/items/:id' => 'context_modules#update_item', :as => :context_modules_update_item, :via => :put
    match 'confirm_action' => 'courses#confirm_action', :as => :confirm_action
    match 'copy' => 'courses#copy', :as => :start_copy, :via => :get
    match 'copy' => 'courses#copy_course', :as => :copy_course, :via => :post
    concerns :media
    match 'user_notes' => 'user_notes#user_notes', :as => :user_notes
    match 'details/sis_publish' => 'courses#sis_publish_status', :as => :sis_publish_status, :via => :get
    match 'details/sis_publish' => 'courses#publish_to_sis', :as => :publish_to_sis, :via => :post
    resources :user_lists, :only => :create
    match 'reset' => 'courses#reset_content', :as => :reset, :via => :post
    resources :alerts
    match 'student_view' => 'courses#student_view', :as => :student_view, :via => :post
    match 'student_view' => 'courses#leave_student_view', :as => :student_view, :via => :delete
    match 'test_student' => 'courses#reset_test_student', :as => :test_student, :via => :delete
    match 'content_migrations' => 'content_migrations#index', :as => :content_migrations, :via => :get
  end

  match 'quiz_statistics/:quiz_statistics_id/files/:file_id/download' => 'files#show', :as => :quiz_statistics_download, :download => '1'

  resources :page_views, :only => [:update]
  match 'media_objects' => 'context#create_media_object', :as => :create_media_object, :via => :post
  match 'media_objects/kaltura_notifications' => 'context#kaltura_notifications', :as => :kaltura_notifications
  match 'media_objects/:id' => 'context#media_object_inline', :as => :media_object
  match 'media_objects/:id/redirect' => 'context#media_object_redirect', :as => :media_object_redirect
  match 'media_objects/:id/thumbnail' => 'context#media_object_thumbnail', :as => :media_object_thumbnail
  match 'media_objects/:media_object_id/info' => 'media_objects#show', :as => :media_object_info
  match 'media_objects/:media_object_id/media_tracks/:id' => 'media_tracks#show', :as => :show_media_tracks, :via => :get
  match 'media_objects/:media_object_id/media_tracks' => 'media_tracks#create', :as => :create_media_tracks, :via => :post
  match 'media_objects/:media_object_id/media_tracks/:media_track_id' => 'media_tracks#destroy', :as => :delete_media_tracks, :via => :delete

  match 'external_content/success/:service' => 'external_content#success', :as => :external_content_success
  match 'external_content/retrieve/oembed' => 'external_content#oembed_retrieve', :as => :external_content_oembed_retrieve
  match 'external_content/cancel/:service' => 'external_content#cancel', :as => :external_content_cancel

  # We offer a bunch of atom and ical feeds for the user to get
  # data out of Instructure.  The :feed_code attribute is keyed
  # off of either a user, and enrollment, a course, etc. based on
  # that item's uuid.  In config/initializers/active_record.rb you'll
  # find a feed_code method to generate the code, and in
  # application_controller there's a get_feed_context to get it back out.
  scope '/feeds' do
    match 'calendars/:feed_code' => 'calendar_events_api#public_feed', :as => :feeds_calendar
    match 'calendars/:feed_code.:format' => 'calendar_events_api#public_feed', :as => :feeds_calendar_format
    match 'forums/:feed_code' => 'discussion_topics#public_feed', :as => :feeds_forum
    match 'forums/:feed_code.:format' => 'discussion_topics#public_feed', :as => :feeds_forum_format
    match 'topics/:discussion_topic_id/:feed_code' => 'discussion_entries#public_feed', :as => :feeds_topic
    match 'topics/:discussion_topic_id/:feed_code.:format' => 'discussion_entries#public_feed', :as => :feeds_topic_format
    match 'announcements/:feed_code' => 'announcements#public_feed', :as => :feeds_announcements
    match 'announcements/:feed_code.:format' => 'announcements#public_feed', :as => :feeds_announcements_format
    match 'courses/:feed_code' => 'courses#public_feed', :as => :feeds_course
    match 'courses/:feed_code.:format' => 'courses#public_feed', :as => :feeds_course_format
    match 'groups/:feed_code' => 'groups#public_feed', :as => :feeds_group
    match 'groups/:feed_code.:format' => 'groups#public_feed', :as => :feeds_group_format
    match 'enrollments/:feed_code' => 'courses#public_feed', :as => :feeds_enrollment
    match 'enrollments/:feed_code.:format' => 'courses#public_feed', :as => :feeds_enrollment_format
    match 'users/:feed_code' => 'users#public_feed', :as => :feeds_user
    match 'users/:feed_code.:format' => 'users#public_feed', :as => :feeds_user_format
    match 'eportfolios/:eportfolio_id.:format' => 'eportfolios#public_feed', :as => :feeds_eportfolio
    match 'conversations/:feed_code' => 'conversations#public_feed', :as => :feeds_conversation
    match 'conversations/:feed_code.:format' => 'conversations#public_feed', :as => :feeds_conversation_format
  end

  resources :assessment_questions do
    match 'files/:id/download' => 'files#assessment_question_show', :as => :map, :download => '1'
    match 'files/:id/preview' => 'files#assessment_question_show', :as => :map, :preview => '1'
    match 'files/:id/:verifier' => 'files#assessment_question_show', :as => :verified_file, :download => '1'
  end

  resources :eportfolios, :except => [:index] do
    match 'reorder_categories' => 'eportfolios#reorder_categories', :as => :reorder_categories
    match ':eportfolio_category_id/reorder_entries' => 'eportfolios#reorder_entries', :as => :reorder_entries
    resources :categories, :controller => :eportfolio_categories
    resources :entries, :controller => :eportfolio_entries do
      resources :page_comments, :path => :comments, :only => ["create", "destroy"]
      match 'files/:attachment_id' => 'eportfolio_entries#attachment', :as => :view_file, :via => :get
      match 'submissions/:submission_id' => 'eportfolio_entries#submission', :as => :preview_submission, :via => :get
    end

    match 'export' => 'eportfolios#export', :as => :export_portfolio
    match 'export.:format' => 'eportfolios#export', :as => :formatted_export_portfolio
    match ':category_name' => 'eportfolio_categories#show', :as => :named_category, :via => :get
    match ':category_name/:entry_name' => 'eportfolio_entries#show', :as => :named_category_entry, :via => :get
  end

  resources :groups do
    concerns :users
    match 'remove_user/:user_id' => 'groups#remove_user', :as => :remove_user, :via => :delete
    match 'add_user' => 'groups#add_user', :as => :add_user
    match 'accept_invitation/:uuid' => 'groups#accept_invitation', :as => :accept_invitation, :via => :get
    match 'members.:format' => 'groups#context_group_members', :as => :members, :via => :get
    match 'members' => 'groups#context_group_members', :as => :members, :via => :get
    match 'undelete' => 'context#undelete_index', :as => :undelete_items
    match 'undelete/:asset_string' => 'context#undelete_item', :as => :undelete_item
    concerns :announcements
    concerns :discussions
    resources :calendar_events
    concerns :files, :file_images, :relative_files, :folders
    concerns :zip_file_imports

    resources :external_tools, :only => [:show] do
      collection do
        get :retrieve
      end
    end

    concerns :wikis
    concerns :conferences
    concerns :media

    resources :collaborations
    match 'calendar' => 'calendars#show', :as => :old_calendar
  end

  resources :accounts do
    match 'settings' => 'accounts#settings', :as => :settings
    match 'admin_tools' => 'accounts#admin_tools', :as => :admin_tools
    match 'account_users' => 'accounts#add_account_user', :as => :add_account_user, :via => :post
    match 'account_users/:id' => 'accounts#remove_account_user', :as => :remove_account_user, :via => :delete
    resources :grading_standards, :only => ["index", "create", "update", "destroy"]
    match 'statistics' => 'accounts#statistics', :as => :statistics
    match 'statistics/over_time/:attribute' => 'accounts#statistics_graph', :as => :statistics_graph
    match 'statistics/over_time/:attribute.:format' => 'accounts#statistics_graph', :as => :formatted_statistics_graph
    match 'turnitin_confirmation' => 'accounts#turnitin_confirmation', :as => :turnitin_confirmation
    resources :permissions, :controller => :role_overrides, :only => [:index, :create] do
      collection do
        post :add_role
        delete :remove_role
      end
    end

    resources :role_overrides, :only => [:index, :create] do
      collection do
        post :add_role
        delete :remove_role
      end
    end

    resources :terms
    resources :sub_accounts

    match 'avatars' => 'accounts#avatars', :as => :avatars
    match 'sis_import' => 'accounts#sis_import', :as => :sis_import, :via => :get
    resources :sis_imports, :only => [:create, :show, :index], :controller => :sis_imports_api
    match 'users' => 'users#create', :as => :add_user, :via => :post
    match 'users/:user_id/delete' => 'accounts#confirm_delete_user', :as => :confirm_delete_user
    match 'users/:user_id' => 'accounts#remove_user', :as => :delete_user, :via => :delete

    resources :users
    resources :account_notifications, :only => [:create, :destroy]
    concerns :announcements
    resources :assignments
    resources :submissions
    match 'account_authorization_configs' => 'account_authorization_configs#update_all', :as => :update_all_authorization_configs, :via => :put
    match 'account_authorization_configs' => 'account_authorization_configs#destroy_all', :as => :remove_all_authorization_configs, :via => :delete
    resources :account_authorization_configs
    match 'test_ldap_connections' => 'account_authorization_configs#test_ldap_connection', :as => :test_ldap_connections
    match 'test_ldap_binds' => 'account_authorization_configs#test_ldap_bind', :as => :test_ldap_binds
    match 'test_ldap_searches' => 'account_authorization_configs#test_ldap_search', :as => :test_ldap_searches
    match 'test_ldap_logins' => 'account_authorization_configs#test_ldap_login', :as => :test_ldap_logins
    match 'saml_testing' => 'account_authorization_configs#saml_testing', :as => :saml_testing
    match 'saml_testing_stop' => 'account_authorization_configs#saml_testing_stop', :as => :saml_testing_stop

    match 'external_tools/sessionless_launch' => 'external_tools#sessionless_launch', :as => :external_tools_sessionless_launch
    resources :external_tools do
      match 'finished' => 'external_tools#finished', :as => :finished
      match 'resource_selection' => 'external_tools#resource_selection', :as => :resource_selection
    end


    get 'lti/basic_lti_launch_request/:message_handler_id', controller: 'lti/message', action: 'basic_lti_launch_request', as: :basic_lti_launch_request
    get 'lti/tool_proxy_registration', controller: 'lti/message', action: 'registration', :as => :tool_proxy_registration


    match 'outcomes/users/:user_id' => 'outcomes#user_outcome_results', :as => :user_outcomes_results
    resources :outcomes do
      match 'results' => 'outcomes#outcome_results', :as => :results
      match 'results/:id' => 'outcomes#outcome_result', :as => :result
      match 'details' => 'outcomes#details', :as => :details
      collection do
        get :list
        post :add_outcome
      end
    end

    resources :outcome_groups, :only => ["create", "update", "destroy"] do
      match 'reorder' => 'outcome_groups#reorder', :as => :reorder
    end

    resources :rubrics
    resources :rubric_associations do
      resources :rubric_assessments, :path => 'assessments'
    end

    concerns :files, :file_images, :relative_files, :folders
    concerns :media
    concerns :groups

    resources :outcomes
    match 'courses' => 'accounts#courses', :as => :courses
    match 'courses.:format' => 'accounts#courses', :as => :courses_formatted
    match 'courses/:id' => 'accounts#courses_redirect', :as => :courses_redirect
    match 'user_notes' => 'user_notes#user_notes', :as => :user_notes
    resources :alerts
    resources :question_banks do
      match 'bookmark' => 'question_banks#bookmark', :as => :bookmark
      match 'reorder' => 'question_banks#reorder', :as => :reorder
      match 'questions' => 'question_banks#questions', :as => :questions
      match 'move_questions' => 'question_banks#move_questions', :as => :move_questions
      resources :assessment_questions
    end

    resources :user_lists, :only => :create

    member do
      get :statistics
    end
  end

  match 'images/users/:user_id' => 'users#avatar_image', :as => :avatar_image, :via => :get
  match 'images/thumbnails/:id/:uuid' => 'files#image_thumbnail', :as => :thumbnail_image
  match 'images/thumbnails/show/:id/:uuid' => 'files#show_thumbnail', :as => :show_thumbnail_image
  match 'images/users/:user_id/report' => 'users#report_avatar_image', :as => :report_avatar_image, :via => :post
  match 'images/users/:user_id' => 'users#update_avatar_image', :as => :update_avatar_image, :via => :put
  match 'all_menu_courses' => 'users#all_menu_courses', :as => :all_menu_courses
  match 'grades' => 'users#grades', :as => :grades
  match 'login' => 'pseudonym_sessions#new', :as => :login, :via => :get
  match 'login' => 'pseudonym_sessions#create', :via => :post
  match 'logout' => 'pseudonym_sessions#destroy', :as => :logout, :via => :delete
  match 'logout' => 'pseudonym_sessions#saml_logout', :via => :post
  match 'logout' => 'pseudonym_sessions#logout_confirm', :via => :get
  match 'login/cas' => 'pseudonym_sessions#new', :as => :cas_login, :via => :get
  match 'login/cas' => 'pseudonym_sessions#cas_logout', :as => :cas_logout, :via => :post
  match 'login/otp' => 'pseudonym_sessions#otp_login', :as => :otp_login, :via => [:get, :post]
  match 'login/:account_authorization_config_id' => 'pseudonym_sessions#new', :as => :aac_login, :via => :get
  match 'users/:user_id/mfa' => 'pseudonym_sessions#disable_otp_login', :as => :disable_mfa, :via => :delete
  match 'file_session/clear' => 'pseudonym_sessions#clear_file_session', :as => :clear_file_session
  match 'register' => 'users#new', :as => :register
  match 'register_from_website' => 'users#new', :as => :register_from_website
  match 'enroll/:self_enrollment_code' => 'self_enrollments#new', :as => :enroll, :via => :get
  match 'services' => 'users#services', :as => :services
  match 'search/bookmarks' => 'users#bookmark_search', :as => :bookmark_search
  match 'search/rubrics' => 'search#rubrics', :as => :search_rubrics
  match 'tours/dismiss/:name' => 'tours#dismiss', :as => :dismiss_tour, :via => :delete
  match 'tours/dismiss/session/:name' => 'tours#dismiss_session', :as => :dismiss_tour_session, :via => :delete
  resources :users do
    match 'masquerade' => 'users#masquerade', :as => :masquerade
    match 'delete' => 'users#delete', :as => :delete
    concerns :files, :file_images
    concerns :zip_file_imports

    resources :page_views, :only => "index"
    resources :folders do
      match 'download' => 'folders#download', :as => :download
    end

    resources :calendar_events
    match 'external_tools/:id' => 'users#external_tool', :as => :external_tool
    resources :rubrics
    resources :rubric_associations do
      resources :rubric_assessments, :path => :assessments
    end

    resources :pseudonyms, :except => ["index"]
    resources :question_banks, :only => [:index]
    match 'assignments_needing_grading' => 'users#assignments_needing_grading', :as => :assignments_needing_grading
    match 'assignments_needing_submitting' => 'users#assignments_needing_submitting', :as => :assignments_needing_submitting
    match 'admin_merge' => 'users#admin_merge', :as => :admin_merge, :via => :get
    match 'merge' => 'users#merge', :as => :merge, :via => :post
    match 'grades' => 'users#grades', :as => :grades
    resources :user_notes
    match 'manageable_courses' => 'users#manageable_courses', :as => :manageable_courses
    match 'outcomes' => 'outcomes#user_outcome_results', :as => :outcomes
    match 'teacher_activity/course/:course_id' => 'users#teacher_activity', :as => :course_teacher_activity
    match 'teacher_activity/student/:student_id' => 'users#teacher_activity', :as => :student_teacher_activity
    match 'media_download' => 'users#media_download', :as => :media_download
    resources :messages, :only => [:index, :create] do
      match 'html_message' => 'messages#html_message', :as => :html_message, :via => :get
    end
  end

  match 'show_message_template' => 'messages#show_message_template', :as => :show_message_template
  match 'message_templates' => 'messages#templates', :as => :message_templates
  resource :profile, :controller => :profile, :only => ["show", "update"] do
    resources :pseudonyms, :except => ["index"]
    resources :tokens, :except => ["index"]
    member do
      put :update_profile
      get :communication
      put :communication_update
      get :settings
      get :observees
    end
  end

  scope '/profile' do
    match 'toggle_disable_inbox' => 'profile#toggle_disable_inbox', :as => :toggle_disable_inbox, :via => :post
    match 'profile_pictures' => 'profile#profile_pics', :as => :profile_pics
    match 'user_services/:id' => 'users#delete_user_service', :as => :profile_user_service, :via => :delete
    match 'user_services' => 'users#create_user_service', :as => :profile_create_user_service, :via => :post
  end

  match 'about/:id' => 'profile#show', :as => :user_profile
  resources :communication_channels
  resource :pseudonym_session

  # dashboard_url is / , not /dashboard
  match '' => 'users#user_dashboard', :as => :dashboard, :via => :get
  match 'dashboard-sidebar' => 'users#dashboard_sidebar', :as => :dashboard_sidebar, :via => :get
  match 'toggle_dashboard' => 'users#toggle_dashboard', :as => :toggle_dashboard, :via => :post
  match 'styleguide' => 'info#styleguide', :as => :styleguide, :via => :get
  match 'old_styleguide' => 'info#old_styleguide', :as => :old_styleguide, :via => :get
  root :to => 'users#user_dashboard', :as => :root, :via => :get
  # backwards compatibility with the old /dashboard url
  match 'dashboard' => 'users#user_dashboard', :as => :dashboard_redirect, :via => :get

  # Thought this idea of having dashboard-scoped urls was a good idea at the
  # time... now I'm not as big a fan.
  resource :dashboard, :only => [] do
    resources :files do
      match 'inline' => 'files#text_show', :as => :text_inline
      match 'download' => 'files#show', :as => :download, :download => '1'
      match 'download.:type' => 'files#show', :as => :typed_download, :download => '1'
      match 'preview' => 'files#show', :as => :preview, :preview => '1'
      match 'inline_view' => 'files#show', :as => :inline_view, :inline => '1'
      match 'contents' => 'files#attachment_content', :as => :attachment_content
      match ':file_path' => 'files#show_relative', :as => :relative_path, :file_path => /.+/
      collection do
        get :quota
        post :reorder
      end
    end

    resources :content_exports, :path => :data_exports
    resources :rubrics, :path => :assessments
  end

  scope '/dashboard' do
    concerns :files
    match 'account_notifications/:id' => 'users#close_notification', :as => :dashboard_close_notification, :via => :delete
    match 'eportfolios' => 'eportfolios#user_index', :as => :dashboard_eportfolios
    match 'grades' => 'users#grades', :as => :dashboard_grades
    match 'comment_session' => 'services_api#start_kaltura_session', :as => :dashboard_comment_session
    match 'ignore_stream_item/:id' => 'users#ignore_stream_item', :as => :dashboard_ignore_stream_item, :via => :delete
  end

  resources :plugins, :only => [:index, :show, :update]

  match 'calendar' => 'calendars#show', :as => :calendar, :via => :get
  match 'calendar2' => 'calendars#show2', :as => :calendar2, :via => :get
  match 'course_sections/:course_section_id/calendar_events/:id' => 'calendar_events#show', :as => :course_section_calendar_event, :via => :get
  match 'switch_calendar/:preferred_calendar' => 'calendars#switch_calendar', :as => :switch_calendar, :via => :post
  match 'files' => 'files#index', :as => :files, :via => :get
  get "files/folder#{full_path_glob}", :controller => :files, :action => :ember_app, :format => false
  get "files/search", :controller => :files, :action => :ember_app, :format => false
  match 'files/s3_success/:id' => 'files#s3_success', :as => :s3_success
  match 'files/:id/public_url' => 'files#public_url', :as => :public_url
  match 'files/preflight' => 'files#preflight', :as => :file_preflight
  match 'files/pending' => 'files#create_pending', :as => :file_create_pending
  resources :assignments, :only => [:index] do
    resources :files, :only => [] do
      match 'inline_view' => 'files#show', :as => :inline_view, :via => :post, :inline => '1'
    end
  end

  resources :appointment_groups, :only => [:index, :show]

  match 'errors' => 'info#record_error', :as => :errors, :via => :post
  match 'record_js_error' => 'info#record_js_error', :as => :record_js_error, :via => :get
  resources :errors, :only => [:show, :index], :path => :error_reports

  match 'health_check' => 'info#health_check', :as => :health_check

  match 'facebook' => 'facebook#index', :as => :facebook
  match 'facebook/message/:id' => 'facebook#hide_message', :as => :facebook_hide_message
  match 'facebook/settings' => 'facebook#settings', :as => :facebook_settings
  match 'facebook/notification_preferences' => 'facebook#notification_preferences', :as => :facebook_notification_preferences

  resources :interaction_tests do
    collection do
      get :next
      get :register
      post :groups
    end
  end

  match 'object_snippet' => 'context#object_snippet', :as => :object_snippet, :via => :post
  match 'saml_consume' => 'pseudonym_sessions#saml_consume', :as => :saml_consume
  match 'saml_logout' => 'pseudonym_sessions#saml_logout', :as => :saml_logout, :via => [:get, :post, :delete]
  match 'saml_meta_data' => 'accounts#saml_meta_data', :as => :saml_meta_data

  # Routes for course exports
  match 'xsd/:version.xsd' => 'content_exports#xml_schema'
  resources :jobs, :only => ["index", "show"] do
    collection do
      post 'batch_update'
    end
  end

  match 'equation_images/:id' => 'equation_images#show', :as => :equation_images, :id => /.+/

  # assignments at the top level (without a context) -- we have some specs that
  # assert these routes exist, but just 404. I'm not sure we ever actually want
  # top-level assignments available, maybe we should change the specs instead.
  resources :assignments, :only => ["index", "show"]

  resources :files do
    match 'download' => 'files#show', :as => :download, :download => '1'
  end

  resources :developer_keys, :only => [:index]

  resources :rubrics do
    resources :rubric_assessments, :path => :assessments
  end

  match 'selection_test' => 'external_content#selection_test', :as => :selection_test

  resources :quiz_submissions do
    concerns :files
  end

  scope(:controller => :outcome_results) do
    get 'courses/:course_id/outcome_rollups', :action => :rollups, :path_name => 'course_outcome_rollups'
  end

  ### API routes ###

  # TODO: api routes can't yet take advantage of concerns for DRYness, because of
  # the way ApiRouteSet works. For now we get around it by defining methods
  # inline in the routes file, but getting concerns working would rawk.
  ApiRouteSet::V1.draw(self) do
    scope(:controller => :courses) do
      get 'courses', :action => :index, :path_name => 'courses'
      put 'courses/:id', :action => :update
      get 'courses/:id', :action => :show, :path_name => 'course'
      delete 'courses/:id', :action => :destroy
      post 'accounts/:account_id/courses', :action => :create
      get 'courses/:course_id/students', :action => :students
      get 'courses/:course_id/settings', :action => :settings, :path_name => 'course_settings'
      put 'courses/:course_id/settings', :action => :update_settings
      get 'courses/:course_id/recent_students', :action => :recent_students, :path_name => 'course_recent_students'
      get 'courses/:course_id/users', :action => :users, :path_name => 'course_users'
      # this api endpoint has been removed, it was redundant with just courses#users
      # we keep it around for backward compatibility though
      get 'courses/:course_id/search_users', :action => :users
      get 'courses/:course_id/users/:id', :action => :user, :path_name => 'course_user'
      get 'courses/:course_id/activity_stream', :action => :activity_stream, :path_name => 'course_activity_stream'
      get 'courses/:course_id/activity_stream/summary', :action => :activity_stream_summary, :path_name => 'course_activity_stream_summary'
      get 'courses/:course_id/todo', :action => :todo_items
      post 'courses/:course_id/preview_html', :action => :preview_html
      post 'courses/:course_id/course_copy', :controller => :content_imports, :action => :copy_course_content
      get 'courses/:course_id/course_copy/:id', :controller => :content_imports, :action => :copy_course_status, :path_name => :course_copy_status
      get  'courses/:course_id/files', :controller => :files, :action => :api_index, :path_name => 'course_files'
      post 'courses/:course_id/files', :action => :create_file, :path_name => 'course_create_file'
      post 'courses/:course_id/folders', :controller => :folders, :action => :create
      get 'courses/:course_id/folders/by_path/*full_path', :controller => :folders, :action => :resolve_path
      get 'courses/:course_id/folders/by_path', :controller => :folders, :action => :resolve_path
      get  'courses/:course_id/folders/:id', :controller => :folders, :action => :show, :path_name => 'course_folder'
      put  'accounts/:account_id/courses', :action => :batch_update
      post 'courses/:course_id/ping', :action => :ping, :path_name => 'course_ping'
    end

    scope(:controller => :account_notifications) do
      post 'accounts/:account_id/account_notifications', :action => :create, :path_name => 'account_notification'
    end

    scope(:controller => :tabs) do
      get "courses/:course_id/tabs", :action => :index, :path_name => 'course_tabs'
      get "groups/:group_id/tabs", :action => :index, :path_name => 'group_tabs'
      put "courses/:course_id/tabs/:tab_id", :action => :update
    end

    scope(:controller => :sections) do
      get 'courses/:course_id/sections', :action => :index, :path_name => 'course_sections'
      get 'courses/:course_id/sections/:id', :action => :show, :path_name => 'course_section'
      get 'sections/:id', :action => :show
      post 'courses/:course_id/sections', :action => :create
      put 'sections/:id', :action => :update
      delete 'sections/:id', :action => :destroy
      post 'sections/:id/crosslist/:new_course_id', :action => :crosslist
      delete 'sections/:id/crosslist', :action => :uncrosslist
    end

    scope(:controller => :enrollments_api) do
      get  'courses/:course_id/enrollments', :action => :index, :path_name => 'course_enrollments'
      get  'sections/:section_id/enrollments', :action => :index, :path_name => 'section_enrollments'
      get  'users/:user_id/enrollments', :action => :index, :path_name => 'user_enrollments'
      get  'accounts/:account_id/enrollments/:id', :action => :show, :path_name => 'enrollment'

      post 'courses/:course_id/enrollments', :action => :create
      post 'sections/:section_id/enrollments', :action => :create

      delete 'courses/:course_id/enrollments/:id', :action => :destroy
    end

    scope(:controller => :terms_api) do
      get 'accounts/:account_id/terms', :action => :index, :path_name => 'enrollment_terms'
    end

    scope(:controller => :authentication_audit_api) do
      get 'audit/authentication/logins/:login_id', :action => :for_login, :path_name => 'audit_authentication_login'
      get 'audit/authentication/accounts/:account_id', :action => :for_account, :path_name => 'audit_authentication_account'
      get 'audit/authentication/users/:user_id', :action => :for_user, :path_name => 'audit_authentication_user'
    end

    scope(:controller => :grade_change_audit_api) do
      get 'audit/grade_change/assignments/:assignment_id', :action => :for_assignment, :path_name => 'audit_grade_change_assignment'
      get 'audit/grade_change/courses/:course_id', :action => :for_course, :path_name => 'audit_grade_change_course'
      get 'audit/grade_change/students/:student_id', :action => :for_student, :path_name => 'audit_grade_change_student'
      get 'audit/grade_change/graders/:grader_id', :action => :for_grader, :path_name => 'audit_grade_change_grader'
    end

    scope(:controller => :course_audit_api) do
      get 'audit/course/courses/:course_id', :action => :for_course, :path_name => 'audit_course_for_course'
    end

    scope(:controller => :assignments_api) do
      get 'courses/:course_id/assignments', :action => :index, :path_name => 'course_assignments'
      get 'courses/:course_id/assignments/:id', :action => :show, :path_name => 'course_assignment'
      post 'courses/:course_id/assignments', :action => :create
      put 'courses/:course_id/assignments/:id', :action => :update
      delete 'courses/:course_id/assignments/:id', :action => :destroy, :controller => :assignments
    end

    scope(:controller => :assignment_overrides) do
      get 'courses/:course_id/assignments/:assignment_id/overrides', :action => :index
      post 'courses/:course_id/assignments/:assignment_id/overrides', :action => :create
      get 'courses/:course_id/assignments/:assignment_id/overrides/:id', :action => :show, :path_name => 'assignment_override'
      put 'courses/:course_id/assignments/:assignment_id/overrides/:id', :action => :update
      delete 'courses/:course_id/assignments/:assignment_id/overrides/:id', :action => :destroy
      get 'sections/:course_section_id/assignments/:assignment_id/override', :action => :section_alias
      get 'groups/:group_id/assignments/:assignment_id/override', :action => :group_alias
    end

    scope(:controller => :submissions_api) do
      def submissions_api(context, path_prefix = context)
        get "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions", :action => :index, :path_name => "#{path_prefix}_assignment_submissions"
        get "#{context.pluralize}/:#{context}_id/students/submissions", :controller => :submissions_api, :action => :for_students, :path_name => "#{path_prefix}_student_submissions"
        get "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id", :action => :show, :path_name => "#{path_prefix}_assignment_submission"
        post "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions", :action => :create, :controller => :submissions
        post "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id/files", :action => :create_file
        put "#{context.pluralize}/:#{context}_id/assignments/:assignment_id/submissions/:user_id", :action => :update, :path_name => "#{path_prefix}_assignment_submission"
      end
      submissions_api("course")
      submissions_api("section", "course_section")
    end

    post '/courses/:course_id/assignments/:assignment_id/submissions/:user_id/comments/files',
      :action => :create_file, :controller => :submission_comments_api

    scope(:controller => :gradebook_history_api) do
      get "courses/:course_id/gradebook_history/days", :action => :days, :path_name => 'gradebook_history'
      get "courses/:course_id/gradebook_history/feed", :action => :feed, :path_name => 'gradebook_history_feed'
      get "courses/:course_id/gradebook_history/:date", :action =>:day_details, :path_name => 'gradebook_history_for_day'
      get "courses/:course_id/gradebook_history/:date/graders/:grader_id/assignments/:assignment_id/submissions", :action => :submissions, :path_name => 'gradebook_history_submissions'
    end

    get 'courses/:course_id/assignment_groups', :controller => :assignment_groups, :action => :index, :path_name => 'course_assignment_groups'
    scope(:controller => :assignment_groups_api) do
      resources :assignment_groups, :path_prefix => "courses/:course_id", :name_prefix => "course_", :except => [:index]
    end

    scope(:controller => :discussion_topics) do
      get 'courses/:course_id/discussion_topics', :action => :index, :path_name => 'course_discussion_topics'
      get 'groups/:group_id/discussion_topics', :action => :index, :path_name => 'group_discussion_topics'
    end

    scope(:controller => :content_migrations) do
      %w(account course group user).each do |context|
        get "#{context.pluralize}/:#{context}_id/content_migrations/migrators", :action => :available_migrators, :path_name => "#{context}_content_migration_migrators_list"
        get "#{context.pluralize}/:#{context}_id/content_migrations/:id", :action => :show, :path_name => "#{context}_content_migration"
        get "#{context.pluralize}/:#{context}_id/content_migrations", :action => :index, :path_name => "#{context}_content_migration_list"
        post "#{context.pluralize}/:#{context}_id/content_migrations", :action => :create, :path_name => "#{context}_content_migration_create"
        put "#{context.pluralize}/:#{context}_id/content_migrations/:id", :action => :update, :path_name => "#{context}_content_migration_update"
        get "#{context.pluralize}/:#{context}_id/content_migrations/:id/selective_data", :action => :content_list, :path_name => "#{context}_content_migration_selective_data"
      end
    end

    scope(:controller => :migration_issues) do
      %w(account course group user).each do |context|
        get "#{context.pluralize}/:#{context}_id/content_migrations/:content_migration_id/migration_issues/:id", :action => :show, :path_name => "#{context}_content_migration_migration_issue"
        get "#{context.pluralize}/:#{context}_id/content_migrations/:content_migration_id/migration_issues", :action => :index, :path_name => "#{context}_content_migration_migration_issue_list"
        post "#{context.pluralize}/:#{context}_id/content_migrations/:content_migration_id/migration_issues", :action => :create, :path_name => "#{context}_content_migration_migration_issue_create"
        put "#{context.pluralize}/:#{context}_id/content_migrations/:content_migration_id/migration_issues/:id", :action => :update, :path_name => "#{context}_content_migration_migration_issue_update"
      end
    end

    scope(:controller => :discussion_topics_api) do
      def topic_routes(context)
        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id", :action => :show, :path_name => "#{context}_discussion_topic"
        post "#{context.pluralize}/:#{context}_id/discussion_topics", :controller => :discussion_topics, :action => :create
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id", :controller => :discussion_topics, :action => :update
        post "#{context.pluralize}/:#{context}_id/discussion_topics/reorder", :controller => :discussion_topics, :action => :reorder
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id", :controller => :discussion_topics, :action => :destroy

        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/view", :action => :view, :path_name => "#{context}_discussion_topic_view"

        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entry_list", :action => :entry_list, :path_name => "#{context}_discussion_topic_entry_list"
        post "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries", :action => :add_entry, :path_name => "#{context}_discussion_add_entry"
        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries", :action => :entries, :path_name => "#{context}_discussion_entries"
        post "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/replies", :action => :add_reply, :path_name => "#{context}_discussion_add_reply"
        get "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/replies", :action => :replies, :path_name => "#{context}_discussion_replies"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:id", :controller => :discussion_entries, :action => :update, :path_name => "#{context}_discussion_update_reply"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:id", :controller => :discussion_entries, :action => :destroy, :path_name => "#{context}_discussion_delete_reply"

        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read", :action => :mark_topic_read, :path_name => "#{context}_discussion_topic_mark_read"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read", :action => :mark_topic_unread, :path_name => "#{context}_discussion_topic_mark_unread"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read_all", :action => :mark_all_read, :path_name => "#{context}_discussion_topic_mark_all_read"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/read_all", :action => :mark_all_unread, :path_name => "#{context}_discussion_topic_mark_all_unread"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/read", :action => :mark_entry_read, :path_name => "#{context}_discussion_topic_discussion_entry_mark_read"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/entries/:entry_id/read", :action => :mark_entry_unread, :path_name => "#{context}_discussion_topic_discussion_entry_mark_unread"
        put "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/subscribed", :action => :subscribe_topic, :path_name => "#{context}_discussion_topic_subscribe"
        delete "#{context.pluralize}/:#{context}_id/discussion_topics/:topic_id/subscribed", :action => :unsubscribe_topic, :path_name => "#{context}_discussion_topic_unsubscribe"
      end
      topic_routes("course")
      topic_routes("group")
    end

    scope(:controller => :collaborations) do
      get 'collaborations/:id/members', :action => :members, :path_name => 'collaboration_members'
    end

    scope(:controller => :external_tools) do
      def et_routes(context)
        get "#{context}s/:#{context}_id/external_tools/sessionless_launch", :action => :generate_sessionless_launch, :path_name => "#{context}_external_tool_sessionless_launch"
        get "#{context}s/:#{context}_id/external_tools/:external_tool_id", :action => :show, :path_name => "#{context}_external_tool_show"
        get "#{context}s/:#{context}_id/external_tools", :action => :index, :path_name => "#{context}_external_tools"
        post "#{context}s/:#{context}_id/external_tools", :action => :create, :path_name => "#{context}_external_tools_create"
        put "#{context}s/:#{context}_id/external_tools/:external_tool_id", :action => :update, :path_name => "#{context}_external_tools_update"
        delete "#{context}s/:#{context}_id/external_tools/:external_tool_id", :action => :destroy, :path_name => "#{context}_external_tools_delete"
      end
      et_routes("course")
      et_routes("account")
    end

    scope(:controller => :external_feeds) do
      def ef_routes(context)
        get "#{context}s/:#{context}_id/external_feeds", :action => :index, :path_name => "#{context}_external_feeds"
        post "#{context}s/:#{context}_id/external_feeds", :action => :create, :path_name => "#{context}_external_feeds_create"
        delete "#{context}s/:#{context}_id/external_feeds/:external_feed_id", :action => :destroy, :path_name => "#{context}_external_feeds_delete"
      end
      ef_routes("course")
      ef_routes("group")
    end

    scope(:controller => :sis_imports_api) do
      post 'accounts/:account_id/sis_imports', :action => :create
      get 'accounts/:account_id/sis_imports/:id', :action => :show
      get 'accounts/:account_id/sis_imports', :action => :index
    end

    scope(:controller => :users) do
      get 'users/self/activity_stream', :action => :activity_stream, :path_name => 'user_activity_stream'
      get 'users/activity_stream', :action => :activity_stream # deprecated
      get 'users/self/activity_stream/summary', :action => :activity_stream_summary, :path_name => 'user_activity_stream_summary'
      delete 'users/self/activity_stream/:id', action: 'ignore_stream_item'
      delete 'users/self/activity_stream', action: 'ignore_all_stream_items'

      put "users/:user_id/followers/self", :action => :follow
      delete "users/:user_id/followers/self", :action => :unfollow

      get 'users/self/todo', :action => :todo_items
      get 'users/self/upcoming_events', :action => :upcoming_events

      delete 'users/self/todo/:asset_string/:purpose', :action => :ignore_item, :path_name => 'users_todo_ignore'
      post 'accounts/:account_id/users', :action => :create
      get 'accounts/:account_id/users', :action => :index, :path_name => 'account_users'
      delete 'accounts/:account_id/users/:id', :action => :destroy

      put 'users/:id', :action => :update
      post 'users/:user_id/files', :action => :create_file

      get  'users/:user_id/files', :controller => :files, :action => :api_index, :path_name => 'user_files'
      post 'users/:user_id/folders', :controller => :folders, :action => :create
      get 'users/:user_id/folders/by_path/*full_path', :controller => :folders, :action => :resolve_path
      get 'users/:user_id/folders/by_path', :controller => :folders, :action => :resolve_path
      get 'users/:user_id/folders/:id', :controller => :folders, :action => :show, :path_name => 'user_folder'

      get 'users/:id/settings', controller: 'users', action: 'settings'
      put 'users/:id/settings', controller: 'users', action: 'settings', path_name: 'user_settings'

      put 'users/:id/merge_into/:destination_user_id', controller: 'users', action: 'merge_into'
      put 'users/:id/merge_into/accounts/:destination_account_id/users/:destination_user_id', controller: 'users', action: 'merge_into'

      scope(:controller => :user_observees) do
        get    'users/:user_id/observees', action: :index, path_name: 'user_observees'
        post   'users/:user_id/observees', action: :create
        get    'users/:user_id/observees/:observee_id', action: :show, path_name: 'user_observee'
        put    'users/:user_id/observees/:observee_id', action: :update
        delete 'users/:user_id/observees/:observee_id', action: :destroy
      end
    end

    scope(:controller => :custom_data) do
      glob = '(/*scope)'
      get "users/:user_id/custom_data#{glob}", action: 'get_data'
      put "users/:user_id/custom_data#{glob}", action: 'set_data'
      delete "users/:user_id/custom_data#{glob}", action: 'delete_data'
    end

    scope(:controller => :pseudonyms) do
      get 'accounts/:account_id/logins', :action => :index, :path_name => 'account_pseudonyms'
      get 'users/:user_id/logins', :action => :index, :path_name => 'user_pseudonyms'
      post 'accounts/:account_id/logins', :action => :create
      put 'accounts/:account_id/logins/:id', :action => :update
      delete 'users/:user_id/logins/:id', :action => :destroy
    end

    scope(:controller => :accounts) do
      get 'accounts', :action => :index, :path_name => :accounts
      get 'accounts/:id', :action => :show, :path_name => :account
      put 'accounts/:id', :action => :update
      get 'accounts/:account_id/courses', :action => :courses_api, :path_name => 'account_courses'
      get 'accounts/:account_id/sub_accounts', :action => :sub_accounts, :path_name => 'sub_accounts'
      get 'accounts/:account_id/courses/:id', :controller => :courses, :action => :show, :path_name => 'account_course_show'
    end

    scope(:controller => :sub_accounts) do
      post 'accounts/:account_id/sub_accounts', :action => :create
    end

    scope(:controller => :role_overrides) do
      get 'accounts/:account_id/roles', :action => :api_index, :path_name => 'account_roles'
      get 'accounts/:account_id/roles/:role', :role => /[^\/]+/, :action => :show
      post 'accounts/:account_id/roles', :action => :add_role
      post 'accounts/:account_id/roles/:role/activate', :role => /[^\/]+/, :action => :activate_role
      put 'accounts/:account_id/roles/:role', :role => /[^\/]+/, :action => :update
      delete 'accounts/:account_id/roles/:role', :role => /[^\/]+/, :action => :remove_role
    end

    scope(:controller => :account_reports) do
      get 'accounts/:account_id/reports/:report', :action => :index
      get 'accounts/:account_id/reports', :action => :available_reports
      get 'accounts/:account_id/reports/:report/:id', :action => :show
      post 'accounts/:account_id/reports/:report', :action => :create, :path_name => 'account_create_report'
      delete 'accounts/:account_id/reports/:report/:id', :action => :destroy
    end

    scope(:controller => :admins) do
      post 'accounts/:account_id/admins', :action => :create
      delete 'accounts/:account_id/admins/:user_id', :action => :destroy
      get 'accounts/:account_id/admins', :action => :index, :path_name => 'account_admins'
    end

    scope(:controller => :account_authorization_configs) do
      get 'accounts/:account_id/account_authorization_configs/discovery_url', :action => :show_discovery_url
      put 'accounts/:account_id/account_authorization_configs/discovery_url', :action => :update_discovery_url, :path_name => 'account_update_discovery_url'
      delete 'accounts/:account_id/account_authorization_configs/discovery_url', :action => :destroy_discovery_url, :path_name => 'account_destroy_discovery_url'

      get 'accounts/:account_id/account_authorization_configs', :action => :index
      get 'accounts/:account_id/account_authorization_configs/:id', :action => :show
      post 'accounts/:account_id/account_authorization_configs', :action => :create, :path_name => 'account_create_aac'
      put 'accounts/:account_id/account_authorization_configs/:id', :action => :update, :path_name => 'account_update_aac'
      delete 'accounts/:account_id/account_authorization_configs/:id', :action => :destroy, :path_name => 'account_delete_aac'
    end

    get 'users/:user_id/page_views', :controller => :page_views, :action => :index, :path_name => 'user_page_views'
    get 'users/:user_id/profile', :controller => :profile, :action => :settings
    get 'users/:user_id/avatars', :controller => :profile, :action => :profile_pics

    # deprecated routes, second one is solely for YARD. preferred API is api/v1/search/recipients
    get 'conversations/find_recipients', :controller => :search, :action => :recipients
    get 'conversations/find_recipients', :controller => :conversations, :action => :find_recipients

    scope(:controller => :conversations) do
      get 'conversations', :action => :index, :path_name => 'conversations'
      post 'conversations', :action => :create
      post 'conversations/mark_all_as_read', :action => :mark_all_as_read
      get 'conversations/batches', :action => :batches, :path_name => 'conversations_batches'
      get 'conversations/unread_count', :action => :unread_count
      get 'conversations/:id', :action => :show
      put 'conversations/:id', :action => :update # stars, subscribed-ness, workflow_state
      delete 'conversations/:id', :action => :destroy
      post 'conversations/:id/add_message', :action => :add_message
      post 'conversations/:id/add_recipients', :action => :add_recipients
      post 'conversations/:id/remove_messages', :action => :remove_messages
      put 'conversations', :action => :batch_update
      delete 'conversations/:id/delete_for_all', :action => :delete_for_all
    end

    scope(:controller => :communication_channels) do
      get 'users/:user_id/communication_channels', :action => :index, :path_name => 'communication_channels'
      post 'users/:user_id/communication_channels', :action => :create
      delete 'users/:user_id/communication_channels/:id', :action => :destroy
      delete 'users/:user_id/communication_channels/:type/:address', :action => :destroy, :constraints => { :address => %r{[^/?]+} }
    end

    scope(:controller => :notification_preferences) do
      get 'users/:user_id/communication_channels/:communication_channel_id/notification_preferences', action: :index
      get 'users/:user_id/communication_channels/:type/:address/notification_preferences', action: :index, :constraints => { :address => %r{[^/?]+} }
      get 'users/:user_id/communication_channels/:communication_channel_id/notification_preferences/:notification', action: :show
      get 'users/:user_id/communication_channels/:type/:address/notification_preferences/:notification', action: :show, :constraints => { :address => %r{[^/?]+} }
      put 'users/self/communication_channels/:communication_channel_id/notification_preferences/:notification', action: :update
      put 'users/self/communication_channels/:type/:address/notification_preferences/:notification', action: :update, :constraints => { :address => %r{[^/?]+} }
      put 'users/self/communication_channels/:communication_channel_id/notification_preferences', action: :update_all
      put 'users/self/communication_channels/:type/:address/notification_preferences', action: :update_all, :constraints => { :address => %r{[^/?]+} }
    end

    scope(:controller => :comm_messages_api) do
      get 'comm_messages', :action => :index, :path_name => 'comm_messages'
    end

    scope(:controller => :services_api) do
      get 'services/kaltura', :action => :show_kaltura_config
      post 'services/kaltura_session', :action => :start_kaltura_session
    end

    scope(:controller => :calendar_events_api) do
      get 'calendar_events', :action => :index, :path_name => 'calendar_events'
      post 'calendar_events', :action => :create
      get 'calendar_events/:id', :action => :show, :path_name => 'calendar_event'
      put 'calendar_events/:id', :action => :update
      delete 'calendar_events/:id', :action => :destroy
      post 'calendar_events/:id/reservations', :action => :reserve
      post 'calendar_events/:id/reservations/:participant_id', :action => :reserve, :path_name => 'calendar_event_reserve'
    end

    scope(:controller => :appointment_groups) do
      get 'appointment_groups', :action => :index, :path_name => 'appointment_groups'
      post 'appointment_groups', :action => :create
      get 'appointment_groups/:id', :action => :show, :path_name => 'appointment_group'
      put 'appointment_groups/:id', :action => :update
      delete 'appointment_groups/:id', :action => :destroy
      get 'appointment_groups/:id/users', :action => :users, :path_name => 'appointment_group_users'
      get 'appointment_groups/:id/groups', :action => :groups, :path_name => 'appointment_group_groups'
    end

    scope(:controller => :groups) do
      resources :groups, :except => [:index]
      get 'users/self/groups', :action => :index, :path_name => "current_user_groups"
      get 'accounts/:account_id/groups', :action => :context_index, :path_name => 'account_user_groups'
      get 'courses/:course_id/groups', :action => :context_index, :path_name => 'course_user_groups'
      get 'groups/:group_id/users', :action => :users, :path_name => 'group_users'
      post 'groups/:group_id/invite', :action => :invite
      post 'groups/:group_id/files', :action => :create_file
      post 'groups/:group_id/preview_html', :action => :preview_html
      post 'group_categories/:group_category_id/groups', :action => :create
      get 'groups/:group_id/activity_stream', :action => :activity_stream, :path_name => 'group_activity_stream'
      get 'groups/:group_id/activity_stream/summary', :action => :activity_stream_summary, :path_name => 'group_activity_stream_summary'
      put "groups/:group_id/followers/self", :action => :follow
      delete "groups/:group_id/followers/self", :action => :unfollow

      scope(:controller => :group_memberships) do
        resources :memberships, :path_prefix => "groups/:group_id", :name_prefix => "group_", :controller => :group_memberships, :except => [:show]
        resources :users, :path_prefix => "groups/:group_id", :name_prefix => "group_", :controller => :group_memberships, :except => [:show, :create]
      end

      get  'groups/:group_id/files', :controller => :files, :action => :api_index, :path_name => 'group_files'
      post 'groups/:group_id/folders', :controller => :folders, :action => :create
      get 'groups/:group_id/folders/by_path/*full_path', :controller => :folders, :action => :resolve_path
      get 'groups/:group_id/folders/by_path', :controller => :folders, :action => :resolve_path
      get 'groups/:group_id/folders/:id', :controller => :folders, :action => :show, :path_name => 'group_folder'
    end

    scope(:controller => :developer_keys) do
      get 'developer_keys', :action => :index
      get 'developer_keys/:id', :action => :show
      delete 'developer_keys/:id', :action => :destroy
      put 'developer_keys/:id', :action => :update
      post 'developer_keys', :action => :create
    end

    scope(:controller => :search) do
      get 'search/rubrics', :action => 'rubrics', :path_name => 'search_rubrics'
      get 'search/recipients', :action => 'recipients', :path_name => 'search_recipients'
    end

    post 'files/:id/create_success', :controller => :files, :action => :api_create_success, :path_name => 'files_create_success'
    get 'files/:id/create_success', :controller => :files, :action => :api_create_success, :path_name => 'files_create_success'

    scope(:controller => :files) do
      post 'files/:id/create_success', :action => :api_create_success, :path_name => 'files_create_success'
      get 'files/:id/create_success', :action => :api_create_success, :path_name => 'files_create_success'
      # 'attachment' (rather than 'file') is used below so modules API can use polymorphic_url to generate an item API link
      get 'files/:id', :action => :api_show, :path_name => 'attachment'
      delete 'files/:id', :action => :destroy
      put 'files/:id', :action => :api_update
      get 'files/:id/:uuid/status', :action => :api_file_status, :path_name => 'file_status'
      get 'files/:id/public_url', :action => :public_url
      %w(course group user).each do |context|
        get "#{context}s/:#{context}_id/files/quota", :action => :api_quota
      end
    end

    scope(:controller => :folders) do
      get 'folders/:id', :action => :show
      get 'folders/:id/folders', :action => :api_index, :path_name => 'list_folders'
      get 'folders/:id/files', :controller => :files, :action => :api_index, :path_name => 'list_files'
      delete 'folders/:id', :action => :api_destroy
      put 'folders/:id', :action => :update
      post 'folders/:folder_id/folders', :action => :create, :path_name => 'create_folder'
      post 'folders/:folder_id/files', :action => :create_file
    end

    scope(:controller => :favorites) do
      get "users/self/favorites/courses", :action => :list_favorite_courses, :path_name => :list_favorite_courses
      post "users/self/favorites/courses/:id", :action => :add_favorite_course, :path_name => :add_favorite_course
      delete "users/self/favorites/courses/:id", :action => :remove_favorite_course, :path_name => :remove_favorite_course
      delete "users/self/favorites/courses", :action => :reset_course_favorites
    end

    scope(:controller => :wiki_pages_api) do
      get "courses/:course_id/front_page", :action => :show_front_page
      get "groups/:group_id/front_page", :action => :show_front_page
      put "courses/:course_id/front_page", :action => :update_front_page
      put "groups/:group_id/front_page", :action => :update_front_page

      get "courses/:course_id/pages", :action => :index, :path_name => 'course_wiki_pages'
      get "groups/:group_id/pages", :action => :index, :path_name => 'group_wiki_pages'
      get "courses/:course_id/pages/:url", :action => :show, :path_name => 'course_wiki_page'
      get "groups/:group_id/pages/:url", :action => :show, :path_name => 'group_wiki_page'
      get "courses/:course_id/pages/:url/revisions", :action => :revisions, :path_name => 'course_wiki_page_revisions'
      get "groups/:group_id/pages/:url/revisions", :action => :revisions, :path_name => 'group_wiki_page_revisions'
      get "courses/:course_id/pages/:url/revisions/latest", :action => :show_revision
      get "groups/:group_id/pages/:url/revisions/latest", :action => :show_revision
      get "courses/:course_id/pages/:url/revisions/:revision_id", :action => :show_revision
      get "groups/:group_id/pages/:url/revisions/:revision_id", :action => :show_revision
      post "courses/:course_id/pages/:url/revisions/:revision_id", :action => :revert
      post "groups/:group_id/pages/:url/revisions/:revision_id", :action => :revert
      post "courses/:course_id/pages", :action => :create
      post "groups/:group_id/pages", :action => :create
      put "courses/:course_id/pages/:url", :action => :update
      put "groups/:group_id/pages/:url", :action => :update
      delete "courses/:course_id/pages/:url", :action => :destroy
      delete "groups/:group_id/pages/:url", :action => :destroy
    end

    scope(:controller => :context_modules_api) do
      get "courses/:course_id/modules", :action => :index, :path_name => 'course_context_modules'
      get "courses/:course_id/modules/:id", :action => :show, :path_name => 'course_context_module'
      put "courses/:course_id/modules", :action => :batch_update
      post "courses/:course_id/modules", :action => :create, :path_name => 'course_context_module_create'
      put "courses/:course_id/modules/:id", :action => :update, :path_name => 'course_context_module_update'
      delete "courses/:course_id/modules/:id", :action => :destroy
    end

    scope(:controller => :context_module_items_api) do
      get "courses/:course_id/modules/:module_id/items", :action => :index, :path_name => 'course_context_module_items'
      get "courses/:course_id/modules/:module_id/items/:id", :action => :show, :path_name => 'course_context_module_item'
      get "courses/:course_id/module_item_redirect/:id", :action => :redirect, :path_name => 'course_context_module_item_redirect'
      get "courses/:course_id/module_item_sequence", :action => :item_sequence
      post "courses/:course_id/modules/:module_id/items", :action => :create, :path_name => 'course_context_module_items_create'
      put "courses/:course_id/modules/:module_id/items/:id", :action => :update, :path_name => 'course_context_module_item_update'
      delete "courses/:course_id/modules/:module_id/items/:id", :action => :destroy
    end

    scope(:controller => 'quizzes/quiz_assignment_overrides') do
      get "courses/:course_id/quizzes/assignment_overrides", :action => :index, :path_name => 'course_quiz_assignment_overrides'
    end

    scope(:controller => 'quizzes/quizzes_api') do
      get "courses/:course_id/quizzes", :action => :index, :path_name => 'course_quizzes'
      post "courses/:course_id/quizzes", :action => :create, :path_name => 'course_quiz_create'
      get "courses/:course_id/quizzes/:id", :action => :show, :path_name => 'course_quiz'
      put "courses/:course_id/quizzes/:id", :action => :update, :path_name => 'course_quiz_update'
      delete "courses/:course_id/quizzes/:id", :action => :destroy, :path_name => 'course_quiz_destroy'
      post "courses/:course_id/quizzes/:id/reorder", :action => :reorder, :path_name => 'course_quiz_reorder'
    end

    scope(:controller => 'quizzes/quiz_submission_users') do
      get "courses/:course_id/quizzes/:id/submission_users", :action => :index, :path_name => 'course_quiz_submission_users'
      post "courses/:course_id/quizzes/:id/submission_users/message", :action => :message, :path_name => 'course_quiz_submission_users_message'
    end

    scope(:controller => 'quizzes/quiz_groups') do
      post "courses/:course_id/quizzes/:quiz_id/groups", :action => :create, :path_name => 'course_quiz_group_create'
      put "courses/:course_id/quizzes/:quiz_id/groups/:id", :action => :update, :path_name => 'course_quiz_group_update'
      delete "courses/:course_id/quizzes/:quiz_id/groups/:id", :action => :destroy, :path_name => 'course_quiz_group_destroy'
      post "courses/:course_id/quizzes/:quiz_id/groups/:id/reorder", :action => :reorder, :path_name => 'course_quiz_group_reorder'
    end

    scope(:controller => 'quizzes/quiz_questions') do
      get "courses/:course_id/quizzes/:quiz_id/questions", :action => :index, :path_name => 'course_quiz_questions'
      get "courses/:course_id/quizzes/:quiz_id/questions/:id", :action => :show, :path_name => 'course_quiz_question'
      post "courses/:course_id/quizzes/:quiz_id/questions", :action => :create, :path_name => 'course_quiz_question_create'
      put "courses/:course_id/quizzes/:quiz_id/questions/:id", :action => :update, :path_name => 'course_quiz_question_update'
      delete "courses/:course_id/quizzes/:quiz_id/questions/:id", :action => :destroy, :path_name => 'course_quiz_question_destroy'
    end

    scope(:controller => 'quizzes/quiz_reports') do
      post "courses/:course_id/quizzes/:quiz_id/reports", :action => :create, :path_name => 'course_quiz_reports_create'
      get "courses/:course_id/quizzes/:quiz_id/reports", :action => :index, :path_name => 'course_quiz_reports'
      get "courses/:course_id/quizzes/:quiz_id/reports/:id", :action => :show, :path_name => 'course_quiz_report'
    end

    scope(:controller => 'quizzes/quiz_submission_files') do
      post 'courses/:course_id/quizzes/:quiz_id/submissions/self/files', :action => :create, :path_name => 'quiz_submission_files'
    end

    scope(:controller => 'quizzes/quiz_submissions_api') do
      get 'courses/:course_id/quizzes/:quiz_id/submissions', :action => :index, :path_name => 'course_quiz_submissions'
      get 'courses/:course_id/quizzes/:quiz_id/submissions/:id', :action => :show, :path_name => 'course_quiz_submission'
      post 'courses/:course_id/quizzes/:quiz_id/submissions', :action => :create, :path_name => 'course_quiz_submission_create'
      put 'courses/:course_id/quizzes/:quiz_id/submissions/:id', :action => :update, :path_name => 'course_quiz_submission_update'
      post 'courses/:course_id/quizzes/:quiz_id/submissions/:id/complete', :action => :complete, :path_name => 'course_quiz_submission_complete'
    end

    scope(:controller => 'quizzes/quiz_extensions') do
      post 'courses/:course_id/quizzes/:quiz_id/extensions', :action => :create, :path_name => 'course_quiz_extensions_create'
    end

    scope(:controller => 'quizzes/course_quiz_extensions') do 
      post 'courses/:course_id/quiz_extensions', :action => :create, :path_name => 'course_quiz_extensions_create'
    end

    scope(:controller => 'quizzes/quiz_submission_questions') do
      get '/quiz_submissions/:quiz_submission_id/questions', :action => :index, :path_name => 'quiz_submission_questions'
      post '/quiz_submissions/:quiz_submission_id/questions', :action => :answer, :path_name => 'quiz_submission_question_answer'
      get '/quiz_submissions/:quiz_submission_id/questions/:id', :action => :show, :path_name => 'quiz_submission_question'
      put '/quiz_submissions/:quiz_submission_id/questions/:id/flag', :action => :flag, :path_name => 'quiz_submission_question_flag'
      put '/quiz_submissions/:quiz_submission_id/questions/:id/unflag', :action => :unflag, :path_name => 'quiz_submission_question_unflag'
    end

    scope(:controller => 'quizzes/quiz_ip_filters') do
      get 'courses/:course_id/quizzes/:quiz_id/ip_filters', :action => :index, :path_name => 'course_quiz_ip_filters'
    end

    scope(:controller => 'quizzes/quiz_statistics') do
      get 'courses/:course_id/quizzes/:quiz_id/statistics', :action => :index, :path_name => 'course_quiz_statistics'
    end

    scope(:controller => 'polling/polls') do
      get "polls", :action => :index, :path_name => 'polls'
      post "polls", :action => :create, :path_name => 'poll_create'
      get "polls/:id", :action => :show, :path_name => 'poll'
      put "polls/:id", :action => :update, :path_name => 'poll_update'
      delete "polls/:id", :action => :destroy, :path_name => 'poll_destroy'
    end

    scope(:controller => 'polling/poll_choices') do
      get "polls/:poll_id/poll_choices", :action => :index, :path_name => 'poll_choices'
      post "polls/:poll_id/poll_choices", :action => :create, :path_name => 'poll_choices_create'
      get "polls/:poll_id/poll_choices/:id", :action => :show, :path_name => 'poll_choice'
      put "polls/:poll_id/poll_choices/:id", :action => :update, :path_name => 'poll_choice_update'
      delete "polls/:poll_id/poll_choices/:id", :action => :destroy, :path_name => 'poll_choice_destroy'
    end

    scope(:controller => 'polling/poll_sessions') do
      get "polls/:poll_id/poll_sessions", :action => :index, :path_name => 'poll_sessions'
      post "polls/:poll_id/poll_sessions", :action => :create, :path_name => 'poll_sessions_create'
      get "polls/:poll_id/poll_sessions/:id", :action => :show, :path_name => 'poll_session'
      put "polls/:poll_id/poll_sessions/:id", :action => :update, :path_name => 'poll_session_update'
      delete "polls/:poll_id/poll_sessions/:id", :action => :destroy, :path_name => 'poll_session_destroy'
      get "polls/:poll_id/poll_sessions/:id/open", :action => :open, :path_name => 'poll_session_publish'
      get "polls/:poll_id/poll_sessions/:id/close", :action => :close, :path_name => 'poll_session_close'

      get "poll_sessions/opened", :action => :opened, :path_name => 'poll_sessions_opened'
      get "poll_sessions/closed", :action => :closed, :path_name => 'poll_sessions_closed'
    end

    scope(:controller => 'polling/poll_submissions') do
      post "polls/:poll_id/poll_sessions/:poll_session_id/poll_submissions", :action => :create, :path_name => 'poll_submissions_create'
      get "polls/:poll_id/poll_sessions/:poll_session_id/poll_submissions/:id", :action => :show, :path_name => 'poll_submission'
    end

    scope(:controller => 'live_assessments/assessments') do
      %w(course).each do |context|
        prefix = "#{context}s/:#{context}_id"
        get "#{prefix}/live_assessments", :action => :index, :path_name => "#{context}_live_assessments"
        post "#{prefix}/live_assessments", :action => :create, :path_name => "#{context}_live_assessment_create"
      end
    end

    scope(:controller => 'live_assessments/results') do
      %w(course).each do |context|
        prefix = "#{context}s/:#{context}_id"
        get "#{prefix}/live_assessments/:assessment_id/results", :action => :index, :path_name => "#{context}_live_assessment_results"
        post "#{prefix}/live_assessments/:assessment_id/results", :action => :create, :path_name => "#{context}_live_assessment_result_create"
      end
    end

    scope(:controller => :outcome_groups_api) do
      def og_routes(context)
        prefix = (context == "global" ? context : "#{context}s/:#{context}_id")
        unless context == "global"
          get "#{prefix}/outcome_groups", :action => :index, :path_name => "#{context}_outcome_groups"
          get "#{prefix}/outcome_group_links", :action => :link_index, :path_name => "#{context}_outcome_group_links"
        end
        get "#{prefix}/root_outcome_group", :action => :redirect, :path_name => "#{context}_redirect"
        get "#{prefix}/outcome_groups/account_chain", :action => :account_chain, :path_name => "#{context}_account_chain"
        get "#{prefix}/outcome_groups/:id", :action => :show, :path_name => "#{context}_outcome_group"
        put "#{prefix}/outcome_groups/:id", :action => :update
        delete "#{prefix}/outcome_groups/:id", :action => :destroy
        get "#{prefix}/outcome_groups/:id/outcomes", :action => :outcomes, :path_name => "#{context}_outcome_group_outcomes"
        get "#{prefix}/outcome_groups/:id/available_outcomes", :action => :available_outcomes, :path_name => "#{context}_outcome_group_available_outcomes"
        post "#{prefix}/outcome_groups/:id/outcomes", :action => :link
        put "#{prefix}/outcome_groups/:id/outcomes/:outcome_id", :action => :link, :path_name => "#{context}_outcome_link"
        delete "#{prefix}/outcome_groups/:id/outcomes/:outcome_id", :action => :unlink
        get "#{prefix}/outcome_groups/:id/subgroups", :action => :subgroups, :path_name => "#{context}_outcome_group_subgroups"
        post "#{prefix}/outcome_groups/:id/subgroups", :action => :create
        post "#{prefix}/outcome_groups/:id/import", :action => :import, :path_name => "#{context}_outcome_group_import"
        post "#{prefix}/outcome_groups/:id/batch", :action => :batch, :path_name => "#{context}_outcome_group_batch"
      end

      og_routes('global')
      og_routes('account')
      og_routes('course')
    end

    scope(:controller => :outcomes_api) do
      get "outcomes/:id", :action => :show, :path_name => "outcome"
      put "outcomes/:id", :action => :update
      delete "outcomes/:id", :action => :destroy
    end

    scope(:controller => :outcome_results) do
      get 'courses/:course_id/outcome_rollups', :action => :rollups, :path_name => 'course_outcome_rollups'
      get 'courses/:course_id/outcome_results', :action => :index, :path_name => 'course_outcome_results'
    end

    scope(:controller => :group_categories) do
      resources :group_categories, :except => [:index, :create]
      get 'accounts/:account_id/group_categories', :action => :index, :path_name => 'account_group_categories'
      get 'courses/:course_id/group_categories', :action => :index, :path_name => 'course_group_categories'
      post 'accounts/:account_id/group_categories', :action => :create
      post 'courses/:course_id/group_categories', :action => :create
      get 'group_categories/:group_category_id/groups', :action => :groups, :path_name => 'group_category_groups'
      get 'group_categories/:group_category_id/users', :action => :users, :path_name => 'group_category_users'
      post 'group_categories/:group_category_id/assign_unassigned_members', :action => 'assign_unassigned_members', :path_name => 'group_category_assign_unassigned_members'
    end

    scope(:controller => :progress) do
      get "progress/:id", :action => :show, :path_name => "progress"
    end

    scope(:controller => :app_center) do
      ['course', 'account'].each do |context|
        prefix = "#{context}s/:#{context}_id/app_center"
        get  "#{prefix}/apps",                      :action => :index,   :path_name => "#{context}_app_center_apps"
        get  "#{prefix}/apps/:app_id/reviews",      :action => :reviews, :path_name => "#{context}_app_center_app_reviews"
        get  "#{prefix}/apps/:app_id/reviews/self", :action => :review,  :path_name => "#{context}_app_center_app_review"
        post "#{prefix}/apps/:app_id/reviews/self", :action => :add_review
      end
    end

    scope(:controller => :feature_flags) do
      ['course', 'account', 'user'].each do |context|
        prefix = "#{context}s/:#{context}_id/features"
        get "#{prefix}", :action => :index, :path_name => "#{context}_features"
        get "#{prefix}/enabled", :action => :enabled_features, :path_name => "#{context}_enabled_features"
        get "#{prefix}/flags/:feature", :action => :show
        put "#{prefix}/flags/:feature", :action => :update
        delete "#{prefix}/flags/:feature", :action => :delete
      end
    end

    scope(:controller => :conferences) do
      %w(course group).each do |context|
        prefix = "#{context}s/:#{context}_id/conferences"
        get prefix, :action => :index, :path_name => "#{context}_conferences"
      end
    end

    scope(:controller => :custom_gradebook_columns_api) do
      prefix = "courses/:course_id/custom_gradebook_columns"
      get prefix, :action => :index, :path_name => "course_custom_gradebook_columns"
      post prefix, :action => :create
      post "#{prefix}/reorder", :action => :reorder,
        :path_name => "custom_gradebook_columns_reorder"
      put "#{prefix}/:id", :action => :update,
        :path_name => "course_custom_gradebook_column"
      delete "#{prefix}/:id", :action => :destroy
    end

    scope(:controller => :custom_gradebook_column_data_api) do
      prefix = "courses/:course_id/custom_gradebook_columns/:id/data"
      get prefix, :action => :index, :path_name => "course_custom_gradebook_column_data"
      put "#{prefix}/:user_id", :action => :update, :path_name => "course_custom_gradebook_column_datum"
    end

    scope(:controller => :content_exports_api) do
      %w(course group user).each do |context|
        context_prefix = "#{context.pluralize}/:#{context}_id"
        prefix = "#{context_prefix}/content_exports"
        get prefix, :action => :index, :path_name => "#{context}_content_exports"
        post prefix, :action => :create
        get "#{prefix}/:id", :action => :show
      end
      get "courses/:course_id/content_list", :action => :content_list, :path_name => "course_content_list"
    end

    scope(:controller => :grading_standards_api) do
      post 'accounts/:account_id/grading_standards', :action => :create
      post 'courses/:course_id/grading_standards', :action => :create
    end

    get '/crocodoc_session', controller: 'crocodoc_sessions', action: 'show', :as => :crocodoc_session
    get '/canvadoc_session', controller: 'canvadoc_sessions', action: 'show', as: :canvadoc_session

  end

  # this is not a "normal" api endpoint in the sense that it is not documented
  # or called directly, it's used as the redirect in the file upload process
  # for local files. it also doesn't use the normal oauth authentication
  # system, so we can't put it in the api uri namespace.
  match 'files_api' => 'files#api_create', :as => :api_v1_files_create, :via => :post

  match 'login/oauth2/auth' => 'pseudonym_sessions#oauth2_auth', :as => :oauth2_auth, :via => :get
  match 'login/oauth2/token' => 'pseudonym_sessions#oauth2_token', :as => :oauth2_token, :via => :post
  match 'login/oauth2/confirm' => 'pseudonym_sessions#oauth2_confirm', :as => :oauth2_auth_confirm, :via => :get
  match 'login/oauth2/accept' => 'pseudonym_sessions#oauth2_accept', :as => :oauth2_auth_accept, :via => :post
  match 'login/oauth2/deny' => 'pseudonym_sessions#oauth2_deny', :as => :oauth2_auth_deny, :via => :get
  match 'login/oauth2/token' => 'pseudonym_sessions#oauth2_logout', :as => :oauth2_logout, :via => :delete

  ApiRouteSet.draw(self, "/api/lti/v1") do
    post "tools/:tool_id/grade_passback", :controller => :lti_api, :action => :grade_passback, :path_name => "lti_grade_passback_api"
    post "tools/:tool_id/ext_grade_passback", :controller => :lti_api, :action => :legacy_grade_passback, :path_name => "blti_legacy_grade_passback_api"
    post "tools/:tool_id/xapi", :controller => :lti_api, :action => :xapi, :path_name => "lti_xapi"
  end

  ApiRouteSet.draw(self, "/api/lti") do
    ['course', 'account'].each do |context|
      prefix = "#{context}s/:#{context}_id"
      get  "#{prefix}/tool_consumer_profile/:tool_consumer_profile_id", controller: 'lti/tool_consumer_profile', action: 'show', :as => "#{context}_tool_consumer_profile"
      post "#{prefix}/tool_proxy", :controller => 'lti/tool_proxy', :action => :create, :path_name => "create_#{context}_lti_tool_proxy"
    end
    #Tool Setting Services
    get "tool_settings/:tool_setting_id",  controller: 'lti/tool_setting', action: :show, as: 'show_lti_tool_settings'
    put "tool_settings/:tool_setting_id",  controller: 'lti/tool_setting', action: :update, as: 'update_lti_tool_settings'

    #Tool Proxy Services
    get  "tool_proxy/:tool_proxy_guid", :controller => 'lti/tool_proxy', :action => :show, :path_name => "show_lti_tool_proxy"

  end

  match '/assets/:package.:extension' => 'jammit#package', :as => :jammit if defined?(Jammit)
end
