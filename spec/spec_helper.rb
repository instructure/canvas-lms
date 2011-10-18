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

Dir.glob("#{File.dirname(__FILE__).gsub(/\\/, "/")}/factories/*.rb").each { |file| require file }

ALL_MODELS = (ActiveRecord::Base.send(:subclasses) +
      Dir["#{RAILS_ROOT}/app/models/*", "#{RAILS_ROOT}/vendor/plugins/*/app/models/*"].collect { |file|
        model = File.basename(file, ".*").camelize.constantize
        next unless model < ActiveRecord::Base
        model
      }).compact.uniq.reject { |model| model.superclass != ActiveRecord::Base || model == Tableless }

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
  else
    model.connection.execute("TRUNCATE TABLE #{model.connection.quote_table_name(model.table_name)}")
  end
end

# wipe out the test db, in case some non-transactional tests crapped out before
# cleaning up after themselves
ALL_MODELS.each { |m| truncate_table(m) }


# Make AR not puke if MySQL auto-commits the transaction
class ActiveRecord::ConnectionAdapters::MysqlAdapter < ActiveRecord::ConnectionAdapters::AbstractAdapter
  def outside_transaction?
    # MySQL ignores creation of savepoints outside of a transaction; so if we can create one
    # and then can't release it because it doesn't exist, we're not in a transaction
    execute('SAVEPOINT outside_transaction')
    !!execute('RELEASE SAVEPOINT outside_transaction') rescue true
  end
end

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  config.global_fixtures = :plugin_settings

  config.include Webrat::Matchers, :type => :views 

  config.before :each do
    Time.zone = 'UTC'
    Account.default.update_attribute(:default_time_zone, 'UTC')
    Setting.reset_cache!
  end

  def account_with_cas(opts={})
    account = opts[:account]
    account ||= Account.create!
    config = AccountAuthorizationConfig.new
    cas_url = opts[:cas_url] || "https://localhost/cas"
    config.auth_type = "cas"
    config.auth_base = cas_url
    config.log_in_url = opts[:cas_log_in_url] if opts[:cas_log_in_url]
    account.account_authorization_configs << config
    account
  end

  def account_with_saml(opts={})
    account = opts[:account]
    account ||= Account.create!
    config = AccountAuthorizationConfig.new
    config.auth_type = "saml"
    config.log_in_url = opts[:saml_log_in_url] if opts[:saml_log_in_url]
    account.account_authorization_configs << config
    account
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
    user(opts)
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
    @user
  end

  def user_with_pseudonym(opts={})
    user(opts) unless opts[:user]
    user = opts[:user] || @user
    username = opts[:username] || "nobody@example.com"
    password = opts[:password] || "asdfasdf"
    password = nil if password == :autogenerate
    @pseudonym = user.pseudonyms.create!(:account => opts[:account] || Account.default, :unique_id => username, :password => password, :password_confirmation => password)
    @cc = @pseudonym.communication_channel = user.communication_channels.create!(:path_type => 'email', :path => username) do |cc|
      cc.workflow_state = 'active' if opts[:active_cc] || opts[:active_all]
      cc.workflow_state = opts[:cc_state] if opts[:cc_state]
    end
    @cc.should_not be_nil
    @cc.should_not be_new_record
    user
  end

  def course_with_student(opts={})
    course(opts)
    student_in_course(opts)
  end

  def course_with_student_logged_in(opts={})
    course_with_student(opts)
    user_session(@user)    
  end

  def student_in_course(opts={})
    @course ||= opts[:course] || course(opts)
    @student = @user = opts[:user] || user(opts)
    @enrollment = @course.enroll_student(@user)
    @enrollment.course = @course
    if opts[:active_enrollment] || opts[:active_all]
      @enrollment.workflow_state = 'active'
      @enrollment.save!
    end
    @course.reload
    @enrollment
  end

  def course_with_teacher(opts={})
    course(opts)
    @user = opts[:user] || user(opts)
    @teacher = @user
    @enrollment = @course.enroll_teacher(@user)
    # set the reverse association
    @enrollment.course = @course
    @enrollment.accept! if opts[:active_enrollment] || opts[:active_all]
    @enrollment
  end

  def course_with_teacher_logged_in(opts={})
    course_with_teacher(opts)
    user_session(@user)
  end

  def group(opts={})
    if opts[:group_context]
      opts[:group_context].groups.create!
    else
      @group = Group.create!
    end
  end

  def group_with_user(opts={})
    group(opts)
    user(opts)
    @group.participating_users << @user
  end

  def group_with_user_logged_in(opts={})
    group_with_user(opts)
    user_session(@user)
  end

  def user_session(user, pseudonym=nil)
    pseudonym ||= mock_model(Pseudonym, {:record => user})
    pseudonym.stub!(:user_id).and_return(user.id)
    pseudonym.stub!(:user).and_return(user)
    pseudonym.stub!(:login_count).and_return(1)
    session = mock_model(PseudonymSession)
    session.stub!(:record).and_return(pseudonym)
    session.stub!(:session_credentials).and_return(nil)
    PseudonymSession.stub!(:find).and_return(session)
  end

  def login_as(username = "nobody@example.com", password = "asdfasdf")
    post_via_redirect "/login",
      "pseudonym_session[unique_id]" => username,
      "pseudonym_session[password]" => password
    assert_response :success
    path.should eql("/?login_success=1")
  end

  def outcome_with_rubric(opts={})
    @outcome_group ||= LearningOutcomeGroup.default_for(@course)
    @outcome = @course.created_learning_outcomes.create!(:description => '<p>This is <b>awesome</b>.</p>', :short_description => 'new outcome')
    @outcome_group.add_item(@outcome)
    @outcome_group.save! 

    @rubric = Rubric.new(:title => 'My Rubric', :context => @course)
    @rubric.data = [
      {
        :points => 3,
        :description => "Outcome row",
        :long_description => @outcome.description,
        :id => 1,
        :ratings => [
          {
            :points => 3,
            :description => "Rockin'",
            :criterion_id => 1,
            :id => 2
          },
          {
            :points => 0,
            :description => "Lame",
            :criterion_id => 1,
            :id => 3
          }
        ],
        :learning_outcome_id => @outcome.id
      },
      {
        :points => 5,
        :description => "no outcome row",
        :long_description => 'non outcome criterion',
        :id => 2,
        :ratings => [
          {
            :points => 5,
            :description => "Amazing",
            :criterion_id => 2,
            :id => 4
          },
          {
            :points => 3,
            :description => "not too bad",
            :criterion_id => 2,
            :id => 5
          },
          {
            :points => 0,
            :description => "no bueno",
            :criterion_id => 2,
            :id => 6
          }
        ]
      }
    ]
    @rubric.instance_variable_set('@outcomes_changed', true)
    @rubric.save!
    @rubric.update_outcome_tags
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
    @conversation.add_message('test')
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

  def enable_cache
    old_cache = RAILS_CACHE
    new_cache = ActiveSupport::Cache::MemoryStore.new
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
  def enable_forgery_protection
    ActionController::Base.class_eval { alias_method :_old_protect, :allow_forgery_protection; def allow_forgery_protection; true; end }
    yield
  ensure
    ActionController::Base.class_eval { alias_method :allow_forgery_protection, :_old_protect }
  end

  def start_test_http_server
    post_lines = []
    server = TCPServer.open(0)
    port = server.addr[1]
    post_lines = []
    server_thread = Thread.new(server, post_lines) do |server, post_lines|
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
      server.close
    end
    return server, server_thread, post_lines
  end
 
  def stub_kaltura
    # trick kaltura into being activated
    Kaltura::ClientV3.stub!(:config).and_return({
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
end
