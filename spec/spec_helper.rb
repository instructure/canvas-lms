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

ALL_MODELS = Dir.glob(File.expand_path(File.dirname(__FILE__) + '/../app/models') + '/*.rb').map{|x| 
  model = File.basename(x, '.rb').split('_').map(&:capitalize).join
  eval(model) rescue nil
}.find_all{|x| x.respond_to? :delete_all and x.count >= 0 rescue false}

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

  def course(opts={})
    @course = Course.create!
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
        account.role_overrides.create(:permission => permission, :enrollment_type => opts[:membership_type] || 'AccountAdmin', :enabled => enabled)
      end
    end
    account_admin_user(opts)
  end

  def account_admin_user(opts={})
    user(opts)
    @user.account_users.create(:account => opts[:account] || Account.default, :membership_type => opts[:membership_type] || 'AccountAdmin')
    @user
  end

  def user(opts={})
    @user = User.create!
    @user.register! if opts[:active_user] || opts[:active_all]
    @user
  end

  def user_with_pseudonym(opts={})
    user(opts) unless opts[:user]
    user = opts[:user] || @user
    username = opts[:username] || "nobody@example.com"
    password = opts[:password] || "asdfasdf"
    @pseudonym = user.pseudonyms.create!(:unique_id => username, :path => username, :password => password, :password_confirmation => password)
    @cc = @pseudonym.communication_channel
    @cc.should_not be_nil
    @cc.should_not be_new_record
    user.communication_channels << @cc
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
    @user = opts[:user] || user(opts)
    @enrollment = @course.enroll_student(@user)
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
    session = mock_model(PseudonymSession)
    session.stub!(:record).and_return(pseudonym)
    session.stub!(:session_credentials).and_return(nil)
    PseudonymSession.stub!(:find).and_return(session)
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

  def process_csv_data(*lines)
    account_model unless @account
  
    tmp = Tempfile.new("sis_rspec")
    path = "#{tmp.path}.csv"
    tmp.close!
    File.open(path, "w+") { |f| f.puts lines.join "\n" }
    
    importer = SIS::SisCsv.process(@account, :files => [ path ], :allow_printing=>false)
    
    File.unlink path
    
    importer
  end
  
  def process_csv_data_cleanly(*lines)
    importer = process_csv_data(*lines)
    importer.errors.should == []
    importer.warnings.should == []
  end

end
