#
# Copyright (C) 2011 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

ENV["RAILS_ENV"] = 'test'
require File.dirname(__FILE__) + "/../config/environment" unless defined?(RAILS_ROOT)
require 'spec'
# require 'spec/autorun'
require 'spec/rails'
require 'webrat'
require 'mocha'
require File.dirname(__FILE__) + '/mocha_extensions'

Dir.glob("#{File.dirname(__FILE__).gsub(/\\/, "/")}/factories/*.rb").each { |file| require file }

ALL_MODELS = (ActiveRecord::Base.send(:subclasses) +
    Dir["#{RAILS_ROOT}/app/models/*", "#{RAILS_ROOT}/vendor/plugins/*/app/models/*"].collect { |file|
      model = File.basename(file, ".*").camelize.constantize
      next unless model < ActiveRecord::Base
      model
    }).compact.uniq.reject { |model| model.superclass != ActiveRecord::Base || model == Tableless }
ALL_MODELS << Version
ALL_MODELS << Delayed::Backend::ActiveRecord::Job::Failed
ALL_MODELS << Delayed::Backend::ActiveRecord::Job


# rspec aliases :describe to :context in a way that it's pretty much defined
# globally on every object. :context is already heavily used in our application,
# so we remove rspec's definition.
module Spec::DSL::Main
  remove_method :context
end

def truncate_table(model)
  case model.connection.adapter_name
    when "SQLite"
      model.delete_all
      begin
        model.connection.execute("delete from sqlite_sequence where name='#{model.connection.quote_table_name(model.table_name)}';")
        model.connection.execute("insert into sqlite_sequence (name, seq) values ('#{model.connection.quote_table_name(model.table_name)}', #{rand(100)});")
      rescue
      end
    when "PostgreSQL"
      begin
        old_proc = model.connection.raw_connection.set_notice_processor {}
        model.connection.execute("TRUNCATE TABLE #{model.connection.quote_table_name(model.table_name)} CASCADE")
      ensure
        model.connection.raw_connection.set_notice_processor(&old_proc)
      end
    else
      model.connection.execute("TRUNCATE TABLE #{model.connection.quote_table_name(model.table_name)}")
  end
end

def truncate_all_tables
  models_by_connection = ALL_MODELS.group_by { |m| m.connection }
  models_by_connection.each do |connection, models|
    if connection.adapter_name == "PostgreSQL"
      connection.execute("TRUNCATE TABLE #{models.map(&:table_name).map { |t| connection.quote_table_name(t) }.join(',')}")
    else
      models.each { |model| truncate_table(model) }
    end
  end
end

# wipe out the test db, in case some non-transactional tests crapped out before
# cleaning up after themselves
truncate_all_tables

# Make AR not puke if MySQL auto-commits the transaction
class ActiveRecord::ConnectionAdapters::MysqlAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
  def outside_transaction?
    # MySQL ignores creation of savepoints outside of a transaction; so if we can create one
    # and then can't release it because it doesn't exist, we're not in a transaction
    execute('SAVEPOINT outside_transaction')
    !!execute('RELEASE SAVEPOINT outside_transaction') rescue true
  end
end

Spec::Matchers.define :encompass do |expected|
  match do |actual|
    if expected.is_a?(Array) && actual.is_a?(Array)
      expected.size == actual.size && expected.zip(actual).all?{|e,a| a.slice(*e.keys) == e}
    elsif expected.is_a?(Hash) && actual.is_a?(Hash)
      actual.slice(*expected.keys) == expected
    else
      false
    end
  end
end

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  config.mock_with :mocha

  config.include Webrat::Matchers, :type => :views

  config.before :all do
    # so before(:all)'s don't get confused
    Account.clear_special_account_cache!
    Notification.after_create { Notification.reset_cache! }
  end

  config.before :each do
    Time.zone = 'UTC'
    Account.clear_special_account_cache!
    Account.default.update_attribute(:default_time_zone, 'UTC')
    Setting.reset_cache!
    HostUrl.reset_cache!
    Notification.reset_cache!
    ActiveRecord::Base.reset_any_instantiation!
    Attachment.clear_cached_mime_ids
    Rails::logger.try(:info, "Running #{self.class.description} #{@method_name}")
  end

  # flush redis before the first spec, and before each spec that comes after
  # one that used redis
  class << Canvas
    attr_accessor :redis_used
    def redis_with_track_usage(*a, &b)
      self.redis_used = true
      redis_without_track_usage(*a, &b)
    end
    alias_method_chain :redis, :track_usage
    Canvas.redis_used = true
  end
  config.before :each do
    if Canvas.redis_enabled? && Canvas.redis_used
      Canvas.redis.flushdb rescue nil
    end
    Canvas.redis_used = false
  end

  def use_remote_services; ENV['ACTUALLY_TALK_TO_REMOTE_SERVICES'].to_i > 0; end

  def account_with_cas(opts={})
    @account = opts[:account]
    @account ||= Account.create!
    config = AccountAuthorizationConfig.new
    cas_url = opts[:cas_url] || "https://localhost/cas"
    config.auth_type = "cas"
    config.auth_base = cas_url
    config.log_in_url = opts[:cas_log_in_url] if opts[:cas_log_in_url]
    @account.account_authorization_configs << config
    @account
  end

  def account_with_saml(opts={})
    @account = opts[:account]
    @account ||= Account.create!
    config = AccountAuthorizationConfig.new
    config.auth_type = "saml"
    config.log_in_url = opts[:saml_log_in_url] if opts[:saml_log_in_url]
    @account.account_authorization_configs << config
    @account
  end

  def course(opts={})
    @course = Course.create!(:name => opts[:course_name], :account => opts[:account])
    @course.offer! if opts[:active_course] || opts[:active_all]
    if opts[:active_all]
      u = User.create!
      u.register!
      e = @course.enroll_teacher(u)
      e.workflow_state = 'active'
      e.save!
      @teacher = u
    end
    @course
  end

  def account_admin_user_with_role_changes(opts={})
    account = opts[:account] || Account.default
    if opts[:role_changes]
      opts[:role_changes].each_pair do |permission, enabled|
        account.role_overrides.create(:permission => permission.to_s, :enrollment_type => opts[:membership_type] || 'AccountAdmin', :enabled => enabled)
      end
    end
    account_admin_user(opts)
  end

  def account_admin_user(opts={})
    @user = opts[:user] || user(opts)
    @admin = @user
    @user.account_users.create(:account => opts[:account] || Account.default, :membership_type => opts[:membership_type] || 'AccountAdmin')
    @user
  end

  def site_admin_user(opts={})
    user(opts)
    @admin = @user
    Account.site_admin.add_user(@user, opts[:membership_type] || 'AccountAdmin')
    @user
  end

  def user(opts={})
    @user = User.create!(:name => opts[:name])
    @user.register! if opts[:active_user] || opts[:active_all]
    @user.workflow_state = opts[:user_state] if opts[:user_state]
    @user
  end

  def user_with_pseudonym(opts={})
    user(opts) unless opts[:user]
    user = opts[:user] || @user
    @pseudonym = pseudonym(user, opts)
    user
  end

  def communication_channel(user, opts={})
    username = opts[:username] || "nobody@example.com"
    @cc = user.communication_channels.create!(:path_type => 'email', :path => username) do |cc|
      cc.workflow_state = 'active' if opts[:active_cc] || opts[:active_all]
      cc.workflow_state = opts[:cc_state] if opts[:cc_state]
    end
    @cc.should_not be_nil
    @cc.should_not be_new_record
    @cc
  end

  def user_with_communication_channel(opts={})
    user(opts) unless opts[:user]
    user = opts[:user] || @user
    @cc = communication_channel(user, opts)
    user
  end

  def pseudonym(user, opts={})
    @spec_pseudonym_count ||= 0
    username = opts[:username] || (@spec_pseudonym_count > 0 ? "nobody+#{@spec_pseudonym_count}@example.com" : "nobody@example.com")
    @spec_pseudonym_count += 1 if username =~ /nobody(\+\d+)?@example.com/
    password = opts[:password] || "asdfasdf"
    password = nil if password == :autogenerate
    @pseudonym = user.pseudonyms.create!(:account => opts[:account] || Account.default, :unique_id => username, :password => password, :password_confirmation => password)
    @pseudonym.communication_channel = communication_channel(user, opts)
    @pseudonym
  end

  def managed_pseudonym(user, opts={})
    other_account = opts[:account] || account_with_saml
    if other_account.password_authentication?
      config = AccountAuthorizationConfig.new
      config.auth_type = "saml"
      config.log_in_url = opts[:saml_log_in_url] if opts[:saml_log_in_url]
      other_account.account_authorization_configs << config
    end
    opts[:account] = other_account
    pseudonym(user, opts)
    @pseudonym.sis_user_id = opts[:sis_user_id] || "U001"
    @pseudonym.save!
    @pseudonym.should be_managed_password
    @pseudonym
  end

  def user_with_managed_pseudonym(opts={})
    user(opts) unless opts[:user]
    user = opts[:user] || @user
    managed_pseudonym(user, opts)
    user
  end

  def course_with_user(enrollment_type, opts={})
    @course = opts[:course] || course(opts)
    @user = opts[:user] || user(opts)
    @enrollment = @course.enroll_user(@user, enrollment_type)
    @enrollment.course = @course # set the reverse association
    if opts[:active_enrollment] || opts[:active_all]
      @enrollment.workflow_state = 'active'
      @enrollment.save!
    end
    @course.reload
    @enrollment
  end

  def course_with_student(opts={})
    course_with_user('StudentEnrollment', opts)
    @student = @user
    @enrollment
  end

  def course_with_ta(opts={})
    course_with_user("TaEnrollment", opts)
    @ta = @user
    @enrollment
  end

  def course_with_student_logged_in(opts={})
    course_with_student(opts)
    user_session(@user)
  end

  def student_in_course(opts={})
    opts[:course] = @course if @course && !opts[:course]
    course_with_student(opts)
  end

  def student_in_section(section, opts={})
    user
    enrollment = section.course.enroll_user(@user, 'StudentEnrollment', :section => section)
    enrollment.workflow_state = 'active'
    enrollment.save!
    @user
  end

  def teacher_in_course(opts={})
    opts[:course] = @course if @course && !opts[:course]
    course_with_teacher(opts)
  end

  def course_with_teacher(opts={})
    course_with_user('TeacherEnrollment', opts)
    @teacher = @user
    @enrollment
  end

  def course_with_designer(opts={})
    course_with_user('DesignerEnrollment', opts)
    @designer = @user
    @enrollment
  end

  def course_with_teacher_logged_in(opts={})
    course_with_teacher(opts)
    user_session(@user)
  end

  def course_with_observer(opts={})
    course_with_user('ObserverEnrollment', opts)
    @observer = @user
    @enrollment
  end

  def course_with_observer_logged_in(opts={})
    course_with_observer(opts)
    user_session(@user)
  end

  def add_section(section_name)
    @course_section = @course.course_sections.create!(:name => section_name)
    @course.reload
  end

  def multiple_student_enrollment(user, section)
    @enrollment = @course.enroll_student(user,
                                         :enrollment_state => "active",
                                         :section => section,
                                         :allow_multiple_enrollments => true)
  end

  def enter_student_view(opts={})
    course = opts[:course] || @course || course(opts)
    @fake_student = course.student_view_student
    post "/users/#{@fake_student.id}/masquerade"
    session[:become_user_id].should == @fake_student.id.to_s
  end

  VALID_GROUP_ATTRIBUTES = [:name, :context, :max_membership, :group_category, :join_level, :description, :is_public, :avatar_attachment]
  def group(opts={})
    @group = (opts[:group_context].try(:groups) || Group).create! opts.slice(VALID_GROUP_ATTRIBUTES)
  end

  def group_with_user(opts={})
    group(opts)
    u = opts[:user] || user(opts)
    workflow_state = opts[:active_all] ? 'accepted' : nil
    @group.add_user(u, workflow_state, opts[:moderator])
  end

  def group_with_user_logged_in(opts={})
    group_with_user(opts)
    user_session(@user)
  end

  def user_session(user, pseudonym=nil)
    pseudonym ||= mock()
    pseudonym.stubs(:record).returns(user)
    pseudonym.stubs(:user_id).returns(user.id)
    pseudonym.stubs(:user).returns(user)
    pseudonym.stubs(:login_count).returns(1)
    session = mock()
    session.stubs(:record).returns(pseudonym)
    session.stubs(:session_credentials).returns(nil)
    session.stubs(:used_basic_auth?).returns(false)
    PseudonymSession.stubs(:find).returns(session)
  end

  def login_as(username = "nobody@example.com", password = "asdfasdf")
    post_via_redirect "/login",
                      "pseudonym_session[unique_id]" => username,
                      "pseudonym_session[password]" => password
    assert_response :success
    path.should eql("/?login_success=1")
  end

  def assignment_quiz(questions, opts={})
    course = opts[:course] || course(:active_course => true)
    user = opts[:user] || user(:active_user => true)
    course.enroll_student(user, :enrollment_state => 'active') unless user.enrollments.any?{|e| e.course_id == course.id}
    @assignment = course.assignments.create(:title => "Test Assignment")
    @assignment.workflow_state = "available"
    @assignment.submission_types = "online_quiz"
    @assignment.save
    @quiz = Quiz.find_by_assignment_id(@assignment.id)
    @questions = questions.map { |q| @quiz.quiz_questions.create!(q) }
    @quiz.generate_quiz_data
    @quiz.published_at = Time.now
    @quiz.workflow_state = "available"
    @quiz.save!
  end

  # The block should return the submission_data. A block is used so
  # that we have access to the @questions variable that is created
  # in this method
  def quiz_with_graded_submission(questions, opts={}, &block)
    assignment_quiz(questions, opts)
    @quiz_submission = @quiz.generate_submission(@user)
    @quiz_submission.mark_completed
    @quiz_submission.submission_data = yield if block_given?
    @quiz_submission.grade_submission
  end

  def survey_with_submission(questions, &block)
    course_with_student(:active_all => true)
    @assignment = @course.assignments.create(:title => "Test Assignment")
    @assignment.workflow_state = "available"
    @assignment.submission_types = "online_quiz"
    @assignment.save
    @quiz = Quiz.find_by_assignment_id(@assignment.id)
    @quiz.anonymous_submissions = true
    @quiz.quiz_type = "graded_survey"
    @questions = questions.map { |q| @quiz.quiz_questions.create!(q) }
    @quiz.generate_quiz_data
    @quiz.save!
    @quiz_submission = @quiz.generate_submission(@user)
    @quiz_submission.mark_completed
    @quiz_submission.submission_data = yield if block_given?
  end

  def rubric_for_course
    @rubric = Rubric.new(:title => 'My Rubric', :context => @course)
    @rubric.data = [
        {
            :points => 3,
            :description => "First row",
            :long_description => "The first row in the rubric",
            :id => 1,
            :ratings => [
                {
                    :points => 3,
                    :description => "Rockin'",
                    :criterion_id => 1,
                    :id => 2
                },
                {
                    :points => 2,
                    :description => "Rockin'",
                    :criterion_id => 1,
                    :id => 3
                },
                {
                    :points => 0,
                    :description => "Lame",
                    :criterion_id => 1,
                    :id => 4
                }
            ]
        }
    ]
    @rubric.save!
  end

  def outcome_with_rubric(opts={})
    @outcome_group ||= LearningOutcomeGroup.default_for(@course)
    @outcome = @course.created_learning_outcomes.create!(:description => '<p>This is <b>awesome</b>.</p>', :short_description => 'new outcome')
    @outcome_group.add_item(@outcome)
    @outcome_group.save!

    @rubric = Rubric.generate(:context => @course,
                              :data => {
                                  :title => 'My Rubric',
                                  :hide_score_total => false,
                                  :criteria => {
                                      "0" => {
                                          :points => 3,
                                          :mastery_points => 0,
                                          :description => "Outcome row",
                                          :long_description => @outcome.description,
                                          :ratings => {
                                              "0" => {
                                                  :points => 3,
                                                  :description => "Rockin'",
                                              },
                                              "1" => {
                                                  :points => 0,
                                                  :description => "Lame",
                                              }
                                          },
                                          :learning_outcome_id => @outcome.id
                                      },
                                      "1" => {
                                          :points => 5,
                                          :description => "no outcome row",
                                          :long_description => 'non outcome criterion',
                                          :ratings => {
                                              "0" => {
                                                  :points => 5,
                                                  :description => "Amazing",
                                              },
                                              "1" => {
                                                  :points => 3,
                                                  :description => "not too bad",
                                              },
                                              "2" => {
                                                  :points => 0,
                                                  :description => "no bueno",
                                              }
                                          }
                                      }
                                  }
                              })
    @rubric.instance_variable_set('@outcomes_changed', true)
    @rubric.save!
    @rubric.update_outcome_tags
  end

  def grading_standard_for(context)
    @standard = context.grading_standards.create!(:title => "My Grading Standard", :standard_data => {
        "scheme_0" => {:name => "A", :value => "0.9"},
        "scheme_1" => {:name => "B", :value => "0.8"},
        "scheme_2" => {:name => "C", :value => "0.7"}
    })
  end

  def eportfolio(opts={})
    user(opts)
    @portfolio = @user.eportfolios.create!
  end
  def eportfolio_with_user(opts={})
    eportfolio(opts)
  end
  def eportfolio_with_user_logged_in(opts={})
    eportfolio_with_user(opts)
    user_session(@user)
  end

  def conversation(*users)
    options = users.last.is_a?(Hash) ? users.pop : {}
    @conversation = (options.delete(:sender) || @me || users.shift).initiate_conversation(users.map(&:id))
    @message = @conversation.add_message('test')
    @conversation.update_attributes(options)
    @conversation.reload
  end

  def media_object(opts={})
    mo = MediaObject.new
    mo.media_id = opts[:media_id] || "1234"
    mo.media_type = opts[:media_type] || "video"
    mo.context = opts[:context] || @user || @course
    mo.user = opts[:user] || @user
    mo.save!
  end

  def assert_status(status=500)
    response.status.to_i.should eql(status)
  end

  def assert_unauthorized
    assert_status(401) #unauthorized
                       #    response.headers['Status'].should eql('401 Unauthorized')
    response.should render_template("shared/unauthorized")
  end

  def assert_require_login
    response.should be_redirect
    flash[:notice].should eql("You must be logged in to access this page")
  end

  def default_uploaded_data
    require 'action_controller'
    require 'action_controller/test_process.rb'
    ActionController::TestUploadedFile.new(File.expand_path(File.dirname(__FILE__) + '/fixtures/scribd_docs/doc.doc'), 'application/msword', true)
  end

  def valid_gradebook_csv_content
    File.read(File.expand_path(File.join(File.dirname(__FILE__), %w(fixtures default_gradebook.csv))))
  end

  def factory_with_protected_attributes(ar_klass, attrs, do_save = true)
    obj = ar_klass.respond_to?(:new) ? ar_klass.new : ar_klass.build
    attrs.each { |k,v| obj.send("#{k}=", attrs[k]) }
    obj.save! if do_save
    obj
  end

  def update_with_protected_attributes!(ar_instance, attrs)
    attrs.each { |k,v| ar_instance.send("#{k}=", attrs[k]) }
    ar_instance.save!
  end

  def update_with_protected_attributes(ar_instance, attrs)
    update_with_protected_attributes!(ar_instance, attrs) rescue false
  end

  def process_csv_data(*lines_or_opts)
    account_model unless @account

    lines = lines_or_opts.reject{|thing| thing.is_a? Hash}
    opts = lines_or_opts.select{|thing| thing.is_a? Hash}.inject({:allow_printing => false}, :merge)

    tmp = Tempfile.new("sis_rspec")
    path = "#{tmp.path}.csv"
    tmp.close!
    File.open(path, "w+") { |f| f.puts lines.flatten.join "\n" }
    opts[:files] = [path]

    importer = SIS::CSV::Import.process(@account, opts)

    File.unlink path

    importer
  end

  def process_csv_data_cleanly(*lines_or_opts)
    importer = process_csv_data(*lines_or_opts)
    importer.errors.should == []
    importer.warnings.should == []
  end

  def enable_cache(new_cache = ActiveSupport::Cache::MemoryStore.new)
    old_cache = RAILS_CACHE
    ActionController::Base.cache_store = new_cache
    silence_warnings { Object.const_set(:RAILS_CACHE, new_cache) }
    old_perform_caching = ActionController::Base.perform_caching
    ActionController::Base.perform_caching = true
    yield
  ensure
    silence_warnings { Object.const_set(:RAILS_CACHE, old_cache) }
    ActionController::Base.cache_store = old_cache
    ActionController::Base.perform_caching = old_perform_caching
  end

  # enforce forgery protection, so we can verify usage of the authenticity token
  def enable_forgery_protection(enable = nil)
    if enable != false
      ActionController::Base.class_eval { alias_method :_old_protect, :allow_forgery_protection; def allow_forgery_protection; true; end }
    end

    yield if block_given?

  ensure
    if enable != true
      ActionController::Base.class_eval { alias_method :allow_forgery_protection, :_old_protect }
    end
  end

  def start_test_http_server(requests=1)
    post_lines = []
    server = TCPServer.open(0)
    port = server.addr[1]
    post_lines = []
    server_thread = Thread.new(server, post_lines) do |server, post_lines|
      requests.times do
        client = server.accept
        content_length = 0
        loop do
          line = client.readline
          post_lines << line.strip unless line =~ /\AHost: localhost:|\AContent-Length: /
          content_length = line.split(":")[1].to_i if line.strip =~ /\AContent-Length: [0-9]+\z/
          if line.strip.blank?
            post_lines << client.read(content_length)
            break
          end
        end
        client.puts("HTTP/1.1 200 OK\nContent-Length: 0\n\n")
        client.close
      end
      server.close
    end
    return server, server_thread, post_lines
  end

  def stub_kaltura
    # trick kaltura into being activated
    Kaltura::ClientV3.stubs(:config).returns({
                                                 'domain' => 'kaltura.example.com',
                                                 'resource_domain' => 'kaltura.example.com',
                                                 'partner_id' => '100',
                                                 'subpartner_id' => '10000',
                                                 'secret_key' => 'fenwl1n23k4123lk4hl321jh4kl321j4kl32j14kl321',
                                                 'user_secret_key' => '1234821hrj3k21hjk4j3kl21j4kl321j4kl3j21kl4j3k2l1',
                                                 'player_ui_conf' => '1',
                                                 'kcw_ui_conf' => '1',
                                                 'upload_ui_conf' => '1'
                                             })
  end

  def attachment_obj_with_context(obj, opts={})
    @attachment = factory_with_protected_attributes(Attachment, valid_attachment_attributes.merge(opts))
    @attachment.context = obj
    @attachment
  end

  def attachment_with_context(obj, opts={})
    attachment_obj_with_context(obj, opts)
    @attachment.save!
    @attachment
  end

  def json_parse(json_string = response.body)
    JSON.parse(json_string.sub(%r{^while\(1\);}, ''))
  end

  def s3_storage!
    Attachment.stubs(:s3_storage?).returns(true)
    Attachment.stubs(:local_storage?).returns(false)
    conn = mock('AWS::S3::Connection')
    AWS::S3::Base.stubs(:connection).returns(conn)
    conn.stubs(:access_key_id).returns('stub_id')
    conn.stubs(:secret_access_key).returns('stub_key')
    Attachment.s3_storage?.should eql(true)
    Attachment.local_storage?.should eql(false)
  end

  def local_storage!
    Attachment.stubs(:s3_storage?).returns(false)
    Attachment.stubs(:local_storage?).returns(true)
    Attachment.local_storage?.should eql(true)
    Attachment.s3_storage?.should eql(false)
    Attachment.local_storage?.should eql(true)
  end

  def run_job(job = Delayed::Job.last(:order => :id))
    case job
    when Hash
      job = Delayed::Job.first(:conditions => job, :order => :id)
    end
    Delayed::Worker.new.perform(job)
  end

  def run_jobs
    while job = Delayed::Job.get_and_lock_next_available(
      'spec run_jobs',
      1.hour,
      Delayed::Worker.queue,
      0,
      Delayed::MAX_PRIORITY)
      run_job(job)
    end
  end

  # send a multipart post request in an integration spec post_params is
  # an array of [k,v] params so that the order of the params can be
  # defined
  def send_multipart(url, post_params = {}, http_headers = {}, method = :post)
    mp = Multipart::MultipartPost.new
    query, headers = mp.prepare_query(post_params)
    send(method, url, query, headers.merge(http_headers))
  end

  def run_transaction_commit_callbacks(conn = ActiveRecord::Base.connection)
    conn.after_transaction_commit_callbacks.each { |cb| cb.call }
    conn.after_transaction_commit_callbacks.clear
  end

  def verify_post_matches(post_lines, expected_post_lines)
    # first lines should match
    post_lines[0].should == expected_post_lines[0]

    # now extract the headers
    post_headers = post_lines[1..post_lines.index("")]
    expected_post_headers = expected_post_lines[1..expected_post_lines.index("")]
    if RUBY_VERSION >= "1.9."
      expected_post_headers << "User-Agent: Ruby"
    end
    post_headers.sort.should == expected_post_headers.sort

    # now check payload
    post_lines[post_lines.index(""),-1].should ==
      expected_post_lines[expected_post_lines.index(""),-1]
  end
end
