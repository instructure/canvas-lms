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

begin
  require RUBY_VERSION >= '2.0.0' ? 'byebug' : 'debugger'
rescue LoadError
end

require 'securerandom'
require 'test/unit' if RUBY_VERSION >= '2.2.0'

RSpec.configure do |c|
  c.raise_errors_for_deprecations!
  c.color = true

  c.around(:each) do |example|
    attempts = 0
    begin
      Timeout::timeout(180) {
        example.run
      }
      if ENV['AUTORERUN']
        e = @example.instance_variable_get('@exception')
        if !e.nil? && (attempts += 1) < 2 && !example.metadata[:no_retry]
          puts "FAILURE: #{@example.description} \n #{e}".red
          puts "RETRYING: #{@example.description}".yellow
          @example.instance_variable_set('@exception', nil)
          redo
        elsif e.nil? && attempts != 0
          puts "SUCCESS: retry passed for \n #{@example.description}".green
        end
      end
    end until true
  end
end

begin
  ; require File.expand_path(File.dirname(__FILE__) + "/../parallelized_specs/lib/parallelized_specs.rb");
rescue LoadError;
end

ENV["RAILS_ENV"] = 'test'

require File.expand_path('../../config/environment', __FILE__) unless defined?(Rails)
require 'rspec/rails'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActionView::TestCase::TestController.view_paths = ApplicationController.view_paths

unless CANVAS_RAILS3
  Time.class_eval do
    def compare_with_round(other)
      other = Time.at(other.to_i, other.usec) if other.respond_to?(:usec)
      Time.at(self.to_i, self.usec).compare_without_round(other)
    end
    alias_method :compare_without_round, :<=>
    alias_method :<=>, :compare_with_round
  end

  # temporary patch to keep things sane
  # TODO: actually fix the deprecation messages once we're on Rails 4 permanently and remove this
  ActiveSupport::Deprecation.silenced = true
end

module RSpec::Rails
  module ViewExampleGroup
    module ExampleMethods
      # normally in rspec 2, assigns returns a newly constructed hash
      # which means that 'assigns[:key] = value' in view specs does nothing
      def assigns
        @assigns ||= super
      end

      alias :view_assigns :assigns

      delegate :content_for, :to => :view

      def render_with_helpers(*args)
        controller_class = ("#{@controller.controller_path.camelize}Controller".constantize rescue nil) || ApplicationController

        controller_class.instance_variable_set(:@js_env, nil)
        # this extends the controller's helper methods to the view
        # however, these methods are delegated to the test controller
        view.singleton_class.class_eval do
          include controller_class._helpers unless included_modules.include?(controller_class._helpers)
        end

        # so create a "real_controller"
        # and delegate the helper methods to it
        @controller.singleton_class.class_eval do
          attr_accessor :real_controller

          controller_class._helper_methods.each do |helper|
            class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{helper}(*args, &block)
              real_controller.send(:#{helper}, *args, &block)
            end
            RUBY
          end
        end

        real_controller = controller_class.new
        real_controller.instance_variable_set(:@_request, @controller.request)
        @controller.real_controller = real_controller

        # just calling "render 'path/to/view'" by default looks for a partial
        if args.first && args.first.is_a?(String)
          file = args.shift
          args = [{:template => file}] + args
        end
        render_without_helpers(*args)
      end

      alias_method_chain :render, :helpers
    end
  end

  module Matchers
    class HaveTag
      include ActionDispatch::Assertions::SelectorAssertions
      include Test::Unit::Assertions

      def initialize(expected)
        @expected = expected
      end

      def matches?(html, &block)
        @selected = [HTML::Document.new(html).root]
        assert_select(*@expected, &block)
        return !@failed
      end

      def assert(val, msg=nil)
        unless !!val
          @msg = msg
          @failed = true
        end
      end

      def failure_message
        @msg
      end

      def failure_message_when_negated
        @msg
      end
    end

    def have_tag(*args)
      HaveTag.new(args)
    end
  end
end

require 'action_controller_test_process'
require File.expand_path(File.dirname(__FILE__) + '/mocha_rspec_adapter')
require File.expand_path(File.dirname(__FILE__) + '/mocha_extensions')
require File.expand_path(File.dirname(__FILE__) + '/ams_spec_helper')

require 'i18n_tasks'
require 'handlebars_tasks'

# if mocha was initialized before rails (say by another spec), CollectionProxy would have
# undef_method'd them; we need to restore them
Mocha::ObjectMethods.instance_methods.each do |m|
  ActiveRecord::Associations::CollectionProxy.class_eval <<-RUBY
    def #{m}; end
    remove_method #{m.inspect}
  RUBY
end

factories = "#{File.dirname(__FILE__).gsub(/\\/, "/")}/factories/*.rb"
Dir.glob(factories).each { |file| require file }

examples = "#{File.dirname(__FILE__).gsub(/\\/, "/")}/shared_examples/*.rb"
Dir.glob(examples).each { |file| require file }

def pend_with_bullet
  if defined?(Bullet) && Bullet.enable?
    skip ('PENDING: Bullet')
  end
end

def require_webmock
  # pull in webmock for selected tests, but leave it disabled by default.
  # funky require order is to skip typhoeus because of an incompatibility
  # see: https://github.com/typhoeus/typhoeus/issues/196
  require 'webmock/util/version_checker'
  require 'webmock/http_lib_adapters/http_lib_adapter_registry'
  require 'webmock/http_lib_adapters/http_lib_adapter'
  require 'webmock/http_lib_adapters/typhoeus_hydra_adapter'
  WebMock::HttpLibAdapterRegistry.instance.http_lib_adapters.delete :typhoeus
  require 'webmock/rspec'
end

# rspec aliases :describe to :context in a way that it's pretty much defined
# globally on every object. :context is already heavily used in our application,
# so we remove rspec's definition. This does not prevent 'context' from being
# used within a 'describe' block.

if defined?(Spec::DSL::Main)
  module Spec::DSL::Main
    remove_method :context if respond_to? :context
  end
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

        # mobile verify expects specific id seq for developer key, this forces the sequence to always start at 101
        model.connection.execute("SELECT setval('developer_keys_id_seq', 100);") if model == DeveloperKey
      ensure
        model.connection.raw_connection.set_notice_processor(&old_proc)
      end
    else
      model.connection.execute("SET FOREIGN_KEY_CHECKS=0")
      model.connection.execute("TRUNCATE TABLE #{model.connection.quote_table_name(model.table_name)}")
      model.connection.execute("SET FOREIGN_KEY_CHECKS=1")
  end
end

def truncate_all_tables
  model_connections = ActiveRecord::Base.descendants.map(&:connection).uniq
  model_connections.each do |connection|
    if connection.adapter_name == "PostgreSQL"
      # use custom SQL to exclude tables from extensions
      table_names = connection.query(<<-SQL, 'SCHEMA').map(&:first)
         SELECT tablename
         FROM pg_tables
         WHERE schemaname = ANY (current_schemas(false)) AND NOT tablename IN (
           SELECT CAST(objid::regclass AS VARCHAR) FROM pg_depend WHERE deptype='e'
         )
      SQL
      table_names.delete('schema_migrations')
      connection.execute("TRUNCATE TABLE #{table_names.map { |t| connection.quote_table_name(t) }.join(',')}")
    else
      connection.tables.each { |model| truncate_table(model) }
    end
  end
end

# wipe out the test db, in case some non-transactional tests crapped out before
# cleaning up after themselves
truncate_all_tables

# Make AR not puke if MySQL auto-commits the transaction
module MysqlOutsideTransaction
  def outside_transaction?
    # MySQL ignores creation of savepoints outside of a transaction; so if we can create one
    # and then can't release it because it doesn't exist, we're not in a transaction
    execute('SAVEPOINT outside_transaction')
    !!execute('RELEASE SAVEPOINT outside_transaction') rescue true
  end
end

module ActiveRecord::ConnectionAdapters
  if defined?(MysqlAdapter)
    MysqlAdapter.send(:include, MysqlOutsideTransaction)
  end
  if defined?(Mysql2Adapter)
    Mysql2Adapter.send(:include, MysqlOutsideTransaction)
  end
end

# Be sure to actually test serializing things to non-existent caches,
# but give Mocks a pass, since they won't exist in dev/prod
Mocha::Mock.class_eval do
  def marshal_dump
    nil
  end

  def marshal_load(data)
    raise "Mocks aren't really serializeable!"
  end

  def to_yaml(opts = {})
    YAML.quick_emit(self.object_id, opts) do |out|
      out.scalar(nil, 'null')
    end
  end

  def respond_to_with_marshalling?(symbol, include_private = false)
    return true if [:marshal_dump, :marshal_load].include?(symbol)
    respond_to_without_marshalling?(symbol, include_private)
  end

  alias_method_chain :respond_to?, :marshalling
end

RSpec::Matchers.define :encompass do |expected|
  match do |actual|
    if expected.is_a?(Array) && actual.is_a?(Array)
      expected.size == actual.size && expected.zip(actual).all? { |e, a| a.slice(*e.keys) == e }
    elsif expected.is_a?(Hash) && actual.is_a?(Hash)
      actual.slice(*expected.keys) == expected
    else
      false
    end
  end
end

RSpec::Matchers.define :match_ignoring_whitespace do |expected|
  def whitespaceless(str)
    str.gsub(/\s+/, '')
  end

  match do |actual|
    whitespaceless(actual) == whitespaceless(expected)
  end
end

module Helpers
  def message(opts={})
    m = Message.new
    m.to = opts[:to] || 'some_user'
    m.from = opts[:from] || 'some_other_user'
    m.subject = opts[:subject] || 'a message for you'
    m.body = opts[:body] || 'nice body'
    m.sent_at = opts[:sent_at] || 5.days.ago
    m.workflow_state = opts[:workflow_state] || 'sent'
    m.user_id = opts[:user_id] || opts[:user].try(:id)
    m.path_type = opts[:path_type] || 'email'
    m.root_account_id = opts[:account_id] || Account.default.id
    m.save!
    m
  end
end

RSpec.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures = false
  config.fixture_path = Rails.root+'spec/fixtures/'
  config.infer_spec_type_from_file_location!

  config.include Helpers

  config.include Onceler::BasicHelpers

  # rspec 2+ only runs global before(:all)'s before the top-level
  # groups, not before each nested one. so we need to reset some
  # things to play nicely with its caching
  Onceler.configure do |c|
    c.before :record do
      Account.clear_special_account_cache!(true)
      Role.ensure_built_in_roles!
      AdheresToPolicy::Cache.clear
      Folder.reset_path_lookups!
    end
  end

  Onceler.instance_eval do
    # since once-ler creates potentially multiple levels of transaction
    # nesting, we need a way to know the base level so we can compare it
    # to AR::Conn#open_transactions. that will tell us if something is
    # "committed" or not (from the perspective of the spec)
    def base_transactions
      # if not recording, it's presumed we're in a spec, in which case
      # transactional fixtures add one more level
      open_transactions + (recording? ? 0 : 1)
    end
  end

  Notification.after_create do
    Notification.reset_cache!
    BroadcastPolicy.notification_finder.refresh_cache
  end

  config.before :all do
    # so before(:all)'s don't get confused
    Account.clear_special_account_cache!(true)
    Role.ensure_built_in_roles!
    AdheresToPolicy::Cache.clear
    # silence migration specs
    ActiveRecord::Migration.verbose = false

    # allow tests to still run in non-DA state even though it's hard-coded on
    Feature.definitions["differentiated_assignments"].send(:instance_variable_set, '@state', 'allowed')
  end

  def delete_fixtures!
    # noop for now, needed for plugin spec tweaks. implementation coming
    # in g/24755
  end

  # UTC for tests, cuz it's easier :P
  Account.time_zone_attribute_defaults[:default_time_zone] = 'UTC'

  config.before :each do
    I18n.locale = :en
    Time.zone = 'UTC'
    LoadAccount.force_special_account_reload = true
    Account.clear_special_account_cache!(true)
    AdheresToPolicy::Cache.clear
    Setting.reset_cache!
    ConfigFile.unstub
    HostUrl.reset_cache!
    Notification.reset_cache!
    ActiveRecord::Base.reset_any_instantiation!
    Attachment.clear_cached_mime_ids
    Folder.reset_path_lookups!
    Role.ensure_built_in_roles!
    RoleOverride.clear_cached_contexts
    Delayed::Job.redis.flushdb if Delayed::Job == Delayed::Backend::Redis::Job
    Rails::logger.try(:info, "Running #{self.class.description} #{@method_name}")
    Attachment.domain_namespace = nil
    $spec_api_tokens = {}
  end

  # this runs on post-merge builds to capture dependencies of each spec;
  # we then use that data to run just the bare minimum subset of selenium
  # specs on the patchset builds
  if ENV["SELINIMUM_CAPTURE"]
    require "selinimum"

    config.before :suite do
      Selinimum::Capture.install!
    end

    config.before do |example|
      Selinimum::Capture.current_example = example
    end

    config.after :suite do
      Selinimum::Capture.report!(ENV["SELINIMUM_BATCH_NAME"])
    end
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
      Canvas.redis.flushdb
    end
    Canvas.redis_used = false
  end

  #****************************************************************
  # There used to be a lot of factory methods here!
  # In an effort to move us toward a nicer test factory solution,
  # all factories should now live in a separate file named to
  # correspond with the model that should be built by the factory.
  # Please see spec/factories for examples!
  #****************************************************************

  def enter_student_view(opts={})
    course = opts[:course] || @course || course(opts)
    @fake_student = course.student_view_student
    post "/users/#{@fake_student.id}/masquerade"
    expect(session[:become_user_id]).to eq @fake_student.id.to_s
  end

  def login_as(username = "nobody@example.com", password = "asdfasdf")
    post_via_redirect "/login",
                      "pseudonym_session[unique_id]" => username,
                      "pseudonym_session[password]" => password
    assert_response :success
    expect(request.fullpath).to eq "/?login_success=1"
  end

  def assert_status(status=500)
    expect(response.status.to_i).to eq status
  end

  def assert_unauthorized
    # we allow either a raw unauthorized or a redirect to login
    unless response.status == 401
       expect(response).to redirect_to(login_url)
    end
  end

  def assert_page_not_found
    yield
    assert_status(404)
  end

  def assert_require_login
    expect(response).to be_redirect
    expect(flash[:warning]).to eq "You must be logged in to access this page"
  end

  def fixture_file_upload(path, mime_type=nil, binary=false)
    Rack::Test::UploadedFile.new(File.join(ActionController::TestCase.fixture_path, path), mime_type, binary)
  end

  def default_uploaded_data
    fixture_file_upload('scribd_docs/doc.doc', 'application/msword', true)
  end

  def valid_gradebook_csv_content
    File.read(File.expand_path(File.join(File.dirname(__FILE__), %w(fixtures default_gradebook.csv))))
  end

  def factory_with_protected_attributes(ar_klass, attrs, do_save = true)
    obj = ar_klass.respond_to?(:new) ? ar_klass.new : ar_klass.build
    attrs.each { |k, v| obj.send("#{k}=", attrs[k]) }
    obj.save! if do_save
    obj
  end

  def update_with_protected_attributes!(ar_instance, attrs)
    attrs.each { |k, v| ar_instance.send("#{k}=", attrs[k]) }
    ar_instance.save!
  end

  def update_with_protected_attributes(ar_instance, attrs)
    update_with_protected_attributes!(ar_instance, attrs) rescue false
  end

  def process_csv_data(*lines)
    opts = lines.extract_options!
    opts.reverse_merge!(allow_printing: false)
    account = opts[:account] || @account || account_model

    tmp = Tempfile.new("sis_rspec")
    path = "#{tmp.path}.csv"
    tmp.close!
    File.open(path, "w+") { |f| f.puts lines.flatten.join "\n" }
    opts[:files] = [path]

    importer = SIS::CSV::Import.process(account, opts)

    File.unlink path

    importer
  end

  def process_csv_data_cleanly(*lines_or_opts)
    importer = process_csv_data(*lines_or_opts)
    expect(importer.errors).to eq []
    expect(importer.warnings).to eq []
  end

  def enable_cache(new_cache=:memory_store)
    new_cache ||= :null_store
    new_cache = ActiveSupport::Cache.lookup_store(new_cache)
    previous_cache = Rails.cache
    Rails.stubs(:cache).returns(new_cache)
    ActionController::Base.stubs(:cache_store).returns(new_cache)
    ActionController::Base.any_instance.stubs(:cache_store).returns(new_cache)
    previous_perform_caching = ActionController::Base.perform_caching
    ActionController::Base.stubs(:perform_caching).returns(true)
    ActionController::Base.any_instance.stubs(:perform_caching).returns(true)
    if block_given?
      begin
        yield
      ensure
        Rails.stubs(:cache).returns(previous_cache)
        ActionController::Base.stubs(:cache_store).returns(previous_cache)
        ActionController::Base.any_instance.stubs(:cache_store).returns(previous_cache)
        ActionController::Base.stubs(:perform_caching).returns(previous_perform_caching)
        ActionController::Base.any_instance.stubs(:perform_caching).returns(previous_perform_caching)
      end
    end
  end

  # enforce forgery protection, so we can verify usage of the authenticity token
  def enable_forgery_protection(enable = true)
    old_value = ActionController::Base.allow_forgery_protection
    ActionController::Base.stubs(:allow_forgery_protection).returns(enable)
    ActionController::Base.any_instance.stubs(:allow_forgery_protection).returns(enable)

    yield if block_given?

  ensure
    if block_given?
      ActionController::Base.stubs(:allow_forgery_protection).returns(old_value)
      ActionController::Base.any_instance.stubs(:allow_forgery_protection).returns(old_value)
    end
  end

  def stub_kaltura
    # trick kaltura into being activated
    CanvasKaltura::ClientV3.stubs(:config).returns({
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

  def json_parse(json_string = response.body)
    JSON.parse(json_string.sub(%r{^while\(1\);}, ''))
  end

  # inspired by http://blog.jayfields.com/2007/08/ruby-calling-methods-of-specific.html
  module AttachmentStorageSwitcher
    BACKENDS = %w{FileSystem S3}.map { |backend| AttachmentFu::Backends.const_get(:"#{backend}Backend") }.freeze

    class As #:nodoc:
      private *instance_methods.select { |m| m !~ /(^__|^\W|^binding$)/ }

      def initialize(subject, ancestor)
        @subject = subject
        @ancestor = ancestor
      end

      def method_missing(sym, *args, &blk)
        @ancestor.instance_method(sym).bind(@subject).call(*args, &blk)
      end
    end

    def self.included(base)
      base.cattr_accessor :current_backend
      base.current_backend = (base.ancestors & BACKENDS).first

      # make sure we have all the backends
      BACKENDS.each do |backend|
        base.send(:include, backend) unless base.ancestors.include?(backend)
      end
      # remove the duplicate callbacks added by multiple backends
      base.before_update.uniq!

      BACKENDS.map(&:instance_methods).flatten.uniq.each do |method|
        # overridden by Attachment anyway; don't re-overwrite it
        next if base.instance_method(method).owner == base
        if method.to_s[-1..-1] == '='
          base.class_eval <<-CODE
          def #{method}(arg)
            self.as(self.class.current_backend).#{method} arg
          end
          CODE
        else
          base.class_eval <<-CODE
          def #{method}(*args, &block)
            self.as(self.class.current_backend).#{method}(*args, &block)
          end
          CODE
        end
      end
    end

    def as(ancestor)
      @__as ||= {}
      unless r = @__as[ancestor]
        r = (@__as[ancestor] = As.new(self, ancestor))
      end
      r
    end
  end

  def s3_storage!(opts = {:stubs => true})
    [Attachment, Thumbnail].each do |model|
      model.send(:include, AttachmentStorageSwitcher) unless model.ancestors.include?(AttachmentStorageSwitcher)
      model.stubs(:current_backend).returns(AttachmentFu::Backends::S3Backend)

      model.stubs(:s3_storage?).returns(true)
      model.stubs(:local_storage?).returns(false)
    end

    if opts[:stubs]
      conn = mock('AWS::S3::Client')

      AWS::S3::S3Object.any_instance.stubs(:read).returns("i am stub data from spec helper. nom nom nom")
      AWS::S3::S3Object.any_instance.stubs(:write).returns(true)
      AWS::S3::S3Object.any_instance.stubs(:create_temp_file).returns(true)
      AWS::S3::S3Object.any_instance.stubs(:client).returns(conn)
      AWS::Core::Configuration.any_instance.stubs(:access_key_id).returns('stub_id')
      AWS::Core::Configuration.any_instance.stubs(:secret_access_key).returns('stub_key')
      AWS::S3::Bucket.any_instance.stubs(:name).returns('no-bucket')
    else
      if Attachment.s3_config.blank? || Attachment.s3_config[:access_key_id] == 'access_key'
        skip "Please put valid S3 credentials in config/amazon_s3.yml"
      end
    end
    expect(Attachment.s3_storage?).to be true
    expect(Attachment.local_storage?).to be false
  end

  def local_storage!
    [Attachment, Thumbnail].each do |model|
      model.send(:include, AttachmentStorageSwitcher) unless model.ancestors.include?(AttachmentStorageSwitcher)
      model.stubs(:current_backend).returns(AttachmentFu::Backends::FileSystemBackend)

      model.stubs(:s3_storage?).returns(false)
      model.stubs(:local_storage?).returns(true)
    end

    expect(Attachment.local_storage?).to be true
    expect(Attachment.s3_storage?).to be false
  end

  def run_job(job)
    Delayed::Worker.new.perform(job)
  end

  def run_jobs
    while job = Delayed::Job.get_and_lock_next_available(
        'spec run_jobs',
        Delayed::Settings.queue,
        0,
        Delayed::MAX_PRIORITY)
      run_job(job)
    end
  end

  def track_jobs
    @jobs_tracking = Delayed::JobTracking.track { yield }
  end

  def created_jobs
    @jobs_tracking.created
  end

  def expects_job_with_tag(tag, count = 1)
    track_jobs do
      yield
    end
    expect(created_jobs.count { |j| j.tag == tag }).to eq count
  end

  # send a multipart post request in an integration spec post_params is
  # an array of [k,v] params so that the order of the params can be
  # defined
  def send_multipart(url, post_params = {}, http_headers = {}, method = :post)
    mp = Multipart::Post.new
    query, headers = mp.prepare_query(post_params)

    # A bug in the testing adapter in Rails 3-2-stable doesn't corretly handle
    # translating this header to the Rack/CGI compatible version:
    # (https://github.com/rails/rails/blob/3-2-stable/actionpack/lib/action_dispatch/testing/integration.rb#L289)
    #
    # This issue is fixed in Rails 4-0 stable, by using a newer version of
    # ActionDispatch Http::Headers which correctly handles the merge
    headers = headers.dup.tap { |h| h['CONTENT_TYPE'] ||= h.delete('Content-type') }

    send(method, url, query, headers.merge(http_headers))
  end

  def content_type_key
    CANVAS_RAILS3 ? 'content-type' : 'Content-Type'
  end

  def force_string_encoding(str, encoding = "UTF-8")
    if str.respond_to?(:force_encoding)
      str.force_encoding(encoding)
    end
    str
  end

  # from minitest, MIT licensed
  def capture_io
    orig_stdout, orig_stderr = $stdout, $stderr
    $stdout, $stderr = StringIO.new, StringIO.new
    yield
    return $stdout.string, $stderr.string
  ensure
    $stdout, $stderr = orig_stdout, orig_stderr
  end

  def verify_post_matches(post_lines, expected_post_lines)
    # first lines should match
    expect(post_lines[0]).to eq expected_post_lines[0]

    # now extract the headers
    post_headers = post_lines[1..post_lines.index("")]
    expected_post_headers = expected_post_lines[1..expected_post_lines.index("")]
    expected_post_headers << "User-Agent: Ruby"
    expect(post_headers.sort).to eq expected_post_headers.sort

    # now check payload
    expect(post_lines[post_lines.index(""), -1]).to eq
        expected_post_lines[expected_post_lines.index(""), -1]
  end

  def compare_json(actual, expected)
    if actual.is_a?(Hash)
      actual.each do |k, v|
        expected_v = expected[k]
        compare_json(v, expected_v)
      end
    elsif actual.is_a?(Array)
      actual.zip(expected).each do |a, e|
        compare_json(a, e)
      end
    else
      if actual.is_a?(Fixnum) || actual.is_a?(Float)
        expect(actual).to eq expected
      else
        expect(actual.to_json).to eq expected.to_json
      end
    end
  end

  class FakeHttpResponse
    def initialize(code, body = nil, headers={})
      @code = code
      @body = body
      @headers = headers
    end

    def read_body(io)
      io << @body
    end

    def code
      @code.to_s
    end

    def [](arg)
      @headers[arg]
    end

    def content_type
      self['content-type']
    end
  end

  def intify_timestamps(object)
    case object
      when Time
        object.to_i
      when Hash
        object.inject({}) { |memo, (k, v)| memo[intify_timestamps(k)] = intify_timestamps(v); memo }
      when Array
        object.map { |v| intify_timestamps(v) }
      else
        object
    end
  end

  # frd class, not a mock, so we can once-ler WebConferences (need to Marshal.dump)
  class WebConferencePluginMock
    attr_reader :id, :settings
    def initialize(id, settings)
      @id = id
      @settings = settings
    end

    def valid_settings?; true; end

    def enabled?; true; end

    def base; end
  end
  def web_conference_plugin_mock(id, settings)
    WebConferencePluginMock.new(id, settings)
  end

  def dummy_io
    fixture_file_upload('scribd_docs/doc.doc', 'application/msword', true)
  end

  def consider_all_requests_local(value)
    Rails.application.config.consider_all_requests_local = value
  end

  # a fast way to create a record, especially if you don't need the actual
  # ruby object. since it just does a straight up insert, you need to
  # provide any non-null attributes or things that would normally be
  # inferred/defaulted prior to saving
  def create_record(klass, attributes, return_type = :id)
    create_records(klass, [attributes], return_type)[0]
  end

  # a little wrapper around bulk_insert that gives you back records or ids
  # in order
  # NOTE: if you decide you want to go add something like this to canvas
  # proper, make sure you have it handle concurrent inserts (this does
  # not, because READ COMMITTED is the default transaction isolation
  # level)
  def create_records(klass, records, return_type = :id)
    return [] if records.empty?
    klass.transaction do
      klass.connection.bulk_insert klass.table_name, records
      scope = klass.order("id DESC").limit(records.size)
      return_type == :record ?
        scope.to_a.reverse :
        scope.pluck(:id).reverse
    end
  end
end

class I18nema::Backend
  def stub(translations)
    @stubs = translations.with_indifferent_access
    singleton_class.instance_eval do
      alias_method :lookup, :lookup_with_stubs
      alias_method :available_locales, :available_locales_with_stubs
    end
    yield
  ensure
    singleton_class.instance_eval do
      alias_method :lookup, :lookup_without_stubs
      alias_method :available_locales, :available_locales_without_stubs
    end
    @stubs = nil
  end

  def lookup_with_stubs(locale, key, scope = [], options = {})
    init_translations unless initialized?
    keys = normalize_keys(locale, key, scope, options[:separator])
    keys.inject(@stubs){ |h,k| h[k] if h.respond_to?(:key) } || direct_lookup(*keys)
  end
  alias_method :lookup_without_stubs, :lookup

  def available_locales_with_stubs
    available_locales_without_stubs | @stubs.keys.map(&:to_sym)
  end
  alias_method :available_locales_without_stubs, :available_locales
end

class String
  def red; colorize(self, "\e[1m\e[31m"); end

  def green; colorize(self, "\e[1m\e[32m"); end

  def dark_green; colorize(self, "\e[32m"); end

  def yellow; colorize(self, "\e[1m\e[33m"); end

  def blue; colorize(self, "\e[1m\e[34m"); end

  def dark_blue; colorize(self, "\e[34m"); end

  def pur; colorize(self, "\e[1m\e[35m"); end

  def colorize(text, color_code)  "#{color_code}#{text}\e[0m" end
end

Dir[Rails.root+'{gems,vendor}/plugins/*/spec_canvas/spec_helper.rb'].each do |f|
  require f
end
