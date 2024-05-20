# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# rubocop:disable Lint/ConstantDefinitionInBlock
# we define some modules and classes inside of blocks like RSpec.configure
# in this file, but we fully expect them to be globally accessible
# moving them outside of the block where they're defined would distance them
# from their use, making things harder to find

begin
  require "debug"
rescue LoadError
  nil
end

require "crystalball"
require "rspec/openapi"

ENV["RAILS_ENV"] = "test"

# SimpleCov needs to be added first thing in the spec_helper.rb
# No other configurations should be loaded/performed before this block
if ENV["COVERAGE"] == "1" && (ENV["SUPPRESS_OUTPUT"] != "1")
  require_relative("canvas_simplecov")
  require_relative("coverage_tool")
  puts "Code Coverage enabled" unless ENV["SUPPRESS_OUTPUT"] == "1"
  CoverageTool.start("RSpec")
end

if ENV["CRYSTALBALL_MAP"] == "1"
  require_relative("support/crystalball")

  Coverage.start unless Coverage.running?
  Crystalball::MapGenerator.start! do |config|
    config.register Crystalball::MapGenerator::CoverageStrategy.new
    config.map_storage_path = "log/results/crystalball_results/#{SecureRandom.uuid}_#{ENV.fetch("PARALLEL_INDEX", "0")}_map.yml"
    config.dump_threshold = 50_000
  end

  module Crystalball
    class MapGenerator
      class CoverageStrategy
        def after_register
          Coverage.start unless Coverage.running?
        end

        def call(example_map, example)
          puts "Calling Coverage Strategy for #{example.inspect}"
          before = Coverage.peek_result
          yield example_map, example
          after = Coverage.peek_result
          example_map.push(*execution_detector.detect(before, after).sort)

          if example.metadata[:location].include?("selenium")
            # rubocop:disable Specs/NoExecuteScript
            js_coverage = ::SeleniumDriverSetup.driver.execute_script("return window.__coverage__")&.keys&.uniq
            # rubocop:enable Specs/NoExecuteScript
            example_map.used_files.concat(js_coverage.sort) if js_coverage
          end
        end
      end
    end
  end
end

require_relative "../config/environment"

require "rspec/rails"

require "webmock"
require "webmock/rspec/matchers"
WebMock.allow_net_connect!
WebMock.enable!
# unlike webmock/rspec, only reset in groups that actually do stubbing
module WebMock::API
  include WebMock::Matchers
  def self.included(other)
    other.before { allow(CanvasHttp).to receive(:insecure_host?).and_return(false) }
    other.after { WebMock.reset! }
  end
end

require "delayed/testing"
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
require "sharding_spec_helper"

# nuke the db (say, if `rake db:migrate RAILS_ENV=test` created records),
# and then ensure people aren't creating records outside the rspec
# lifecycle, e.g. inside a describe/context block rather than a
# let/before/example
TestDatabaseUtils.reset_database! unless ENV["DB_VALIDITY_ENSURED"] == "1"
TestDatabaseUtils.check_migrations! unless ENV["DB_VALIDITY_ENSURED"] == "1"
Setting.reset_cache!
BlankSlateProtection.install!
GreatExpectations.install!

ActionView::TestCase::TestController.view_paths = ApplicationController.view_paths
ActionView::Base.streaming_completion_on_exception = "</html>"

# this makes sure that a broken transaction becomes functional again
# by the time we hit rescue_action_in_public, so that the error report
# can be recorded
module SpecTransactionWrapper
  def self.wrap_block_in_transaction(block)
    exception = nil
    ActiveRecord::Base.transaction(joinable: false, requires_new: true) do
      block.call
    rescue ActiveRecord::StatementInvalid
      # these need to properly roll back the transaction
      raise
    rescue
      # anything else, the transaction needs to commit, but we need to re-raise outside the transaction
      exception = $!
    end
    raise exception if exception
  end
end
ActionController::Base.set_callback(:process_action,
                                    :around,
                                    ->(_r, block) { SpecTransactionWrapper.wrap_block_in_transaction(block) })

ActionController::Base.set_callback(:process_action,
                                    :before,
                                    ->(_r) { @streaming_template = false })

module RSpec::Core::Hooks
  class AfterContextHook < Hook
    def run(example)
      exception_class = if defined?(RSpec::Support::AllExceptionsExceptOnesWeMustNotRescue)
                          RSpec::Support::AllExceptionsExceptOnesWeMustNotRescue
                        else
                          Exception
                        end
      example.instance_exec(example, &block)
    rescue exception_class => e
      # TODO: Come up with a better solution for this.
      RSpec.configuration.reporter.message <<~TEXT
        An error occurred in an `after(:context)` hook.
          #{e.class}: #{e.message}
          occurred at #{e.backtrace.join("\n")}
      TEXT
    end
  end
end

Time.class_eval do
  def compare_with_round(other)
    other = Time.at(other.to_i, other.usec) if other.respond_to?(:usec)
    Time.at(to_i, usec).compare_without_round(other)
  end
  alias_method :compare_without_round, :<=>
  alias_method :<=>, :compare_with_round
end

# we use ivars too extensively for factories; prevent them from
# being propagated to views in view specs
# yes, I'm overwriting the method in-place, rather than prepend,
# because the ancestor chain for RSpec::Rails::ViewExampleGroup
# has already been built, and I can't put myself between the two
module ActionView::TestCase::Behavior
  def view_assigns
    if is_a?(RSpec::Rails::HelperExampleGroup)
      # the original implementation. we can't call super because
      # we replaced the whole original method
      return _user_defined_ivars.to_h do |ivar|
        [ivar[1..].to_sym, instance_variable_get(ivar)]
      end
    end
    {}
  end
end

if ENV["ENABLE_AXE_SELENIUM"] == "1"
  require "stormbreaker"
  Stormbreaker.install!
  Stormbreaker.configure do |config|
    config.driver = -> { SeleniumDriverSetup.driver }
    config.skip = [:"color-contrast", :"duplicate-id"]
    config.rules = %i[wcag2a wcag2aa section508]
    if ENV["RSPEC_PROCESSES"]
      config.serialize_output = true
      config.serialize_prefix = "log/results/stormbreaker_results"
    end
  end
end

module RSpec::Rails
  module ViewExampleGroup
    module ExampleMethods
      delegate :content_for, to: :view
    end
  end

  RSpec::Matchers.define :have_tag do |expected|
    match do |actual|
      !!Nokogiri::HTML5(actual).at_css(expected)
    end
  end

  RSpec::Matchers.define :be_checked do
    match do |node|
      if node.is_a?(Nokogiri::XML::Element)
        node.attr("checked") == "checked"
      elsif node.respond_to?(:checked?)
        node.checked?
      end
    end
  end
end

module ReadOnlySecondaryStub
  def self.reset
    ActiveRecord::Base.connection.execute("RESET ROLE")
    Thread.current[:stubbed_guard_rail_env] = nil
  end

  def datbase_username
    Rails.configuration.database_configuration.dig("test", "username") ||
      `whoami`.strip
  end

  def readonly_user_exists?
    return @read_only_user if instance_variable_defined?(:@read_only_user)

    @read_only_user = !!ActiveRecord::Base.connection.select_value("SELECT 1 AS one FROM pg_roles WHERE pg_roles.rolname='canvas_readonly_user'")
  end

  def readonly_user_can_read?
    return @literate if instance_variable_defined?(:@literate)

    sql = "SELECT privilege_type FROM information_schema.table_privileges WHERE grantee ='canvas_readonly_user' AND table_name = 'courses'"
    @literate = ActiveRecord::Base.connection.select_values(sql).include?("SELECT")
  end

  def test_db_name
    ActiveRecord::Base.connection.current_database
  end

  def switch_role!(env)
    if readonly_user_exists? && readonly_user_can_read?
      ActiveRecord::Base.connection.execute((env == :secondary) ? "SET ROLE canvas_readonly_user" : "RESET ROLE")
    else
      puts "The database #{test_db_name} is not setup with a secondary/readonly_user to fix run the following."
      puts "psql -c 'ALTER USER #{datbase_username} CREATEDB CREATEROLE' -d #{test_db_name}"
      puts "psql -c 'GRANT canvas_readonly_user TO #{datbase_username}' -d #{test_db_name}"
      puts "RAILS_ENV=#{Rails.env} bundle exec rake db:migrate:redo VERSION=20211101220306"
    end
  end

  def environment
    Thread.current[:stubbed_guard_rail_env] || super
  end

  def activate(env)
    return super if environment == :deploy
    return super unless [:primary, :secondary].include?(env)

    previous_stub = Thread.current[:stubbed_guard_rail_env]
    previous_env = previous_stub || :primary
    return yield if previous_env == env

    begin
      switch_role!(env)
      Thread.current[:stubbed_guard_rail_env] = env
      yield
    ensure
      switch_role!(previous_env)
      Thread.current[:stubbed_guard_rail_env] = previous_stub
    end
  end
end
GuardRail.singleton_class.prepend ReadOnlySecondaryStub

module ForceTransactionCommitCallbacksToPrimary
  def commit_records
    GuardRail.activate(:primary) do
      super
    end
  end
end
ActiveRecord::ConnectionAdapters::Transaction.prepend ForceTransactionCommitCallbacksToPrimary

module RenderWithHelpers
  def assign(key, value)
    @assigned_variables ||= {}
    @assigned_variables[key] = value
    super
  end

  def render(*args)
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
        class_eval <<~RUBY, __FILE__, __LINE__ + 1
          def #{helper}(*args, &block)
            real_controller.send(:#{helper}, *args, &block)
          end
        RUBY
      end
    end

    real_controller = controller_class.new
    real_controller.instance_variable_set(:@_request, @controller.request)
    real_controller.instance_variable_set(:@context, @controller.instance_variable_get(:@context))
    @assigned_variables&.each do |key, value|
      real_controller.instance_variable_set(:"@#{key}", value)
    end
    if real_controller.instance_variable_get(:@domain_root_account).nil?
      real_controller.instance_variable_set(:@domain_root_account, Account.default)
    end
    @controller.real_controller = real_controller

    # just calling "render 'path/to/view'" by default looks for a partial
    if args.first.is_a?(String)
      file = args.shift
      args = [{ template: file }] + args
    end
    super(*args)
  end
end
RSpec::Rails::ViewExampleGroup::ExampleMethods.prepend(RenderWithHelpers)

require "rspec_mock_extensions"
require "ams_spec_helper"

require "i18n_tasks"
require "factories"

Dir[File.dirname(__FILE__) + "/shared_examples/**/*.rb"].each { |f| require f }

# rspec aliases :describe to :context in a way that it's pretty much defined
# globally on every object. :context is already heavily used in our application,
# so we remove rspec's definition. This does not prevent 'context' from being
# used within a 'describe' block.

if defined?(Spec::DSL::Main)
  module Spec::DSL::Main
    remove_method :context if respond_to? :context
  end
end

RSpec::Mocks.configuration.allow_message_expectations_on_nil = false

module RSpec::Matchers::Helpers
  # allows for matchers to use symbols and literals even though URIs are always strings.
  # i.e. `and_query({assignment_id: @assignment.id})`
  def self.cast_to_strings(expected:)
    expected.to_h { |k, v| [k.to_s, v.to_s] }
  end
end

module Helpers
  def assert_status(status = 500)
    expect(response.status.to_i).to eq status
  end

  def assert_unauthorized
    # we allow either a raw unauthorized or a redirect to login
    if response.status.to_i == 401
      assert_status(401)
    else
      # Certain responses require more privileges than the current user has (ie site admin)
      expect(response).to redirect_to(login_url)
        .or redirect_to(root_url)
    end
  end

  def assert_forbidden
    assert_status(403)
  end

  def assert_page_not_found
    yield
    assert_status(404)
  end

  def assert_require_login
    expect(response).to be_redirect
    expect(flash[:warning]).to eq "You must be logged in to access this page"
  end
end

RSpec::Expectations.configuration.on_potential_false_positives = :raise

require "rspec_junit_formatter"

RSpec.configure do |config|
  config.example_status_persistence_file_path = Rails.root.join("tmp/rspec#{ENV.fetch("PARALLEL_INDEX", "0").to_i}")
  config.fail_if_no_examples = true
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures = false
  if $canvas_rails == "7.0"
    config.fixture_path = Rails.root.join("spec/fixtures")
  else
    config.fixture_paths = [Rails.root.join("spec/fixtures")]
  end
  config.infer_spec_type_from_file_location!
  config.raise_errors_for_deprecations!
  config.color = true
  config.order = :random

  # The Pact specs have prerequisite setup steps so we exclude them by default
  config.filter_run_excluding :pact_live_events if ENV.fetch("RUN_LIVE_EVENTS_CONTRACT_TESTS", "0") == "0"

  if ENV["CRYSTALBALL_MAP"] == "1"
    config.filter_run_excluding :pact_live_events
    config.filter_run_excluding :pact
  end

  # The Pact build needs RspecJunitFormatter and does not run RSpecQ
  file = "log/results/results-#{ENV.fetch("PARALLEL_INDEX", "0").to_i}.xml"
  config.add_formatter "RspecJunitFormatter", file if (ENV["PACT_BROKER"] && ENV["JENKINS_HOME"]) || ENV["CRYSTALBALL_MAP"] == "1"

  config.include Helpers
  config.include Factories
  config.include RequestHelper, type: :request
  config.include Onceler::BasicHelpers
  config.include ActionDispatch::TestProcess::FixtureFile
  config.project_source_dirs << "gems" # so that failures here are reported properly

  if ENV["RSPEC_LOG"]
    config.add_formatter "ParallelTests::RSpec::RuntimeLogger", "log/parallel_runtime/parallel_runtime_rspec_tests-#{ENV.fetch("PARALLEL_INDEX", "0").to_i}.log"
  end

  if ENV["RAILS_LOAD_ALL_LOCALES"] && RSpec.configuration.filter.rules[:i18n]
    config.around do |example|
      SpecMultipleLocales.run(example)
    end
  end

  if ENV["OPENAPI"]
    config.define_derived_metadata(file_path: %r{spec/controllers}) do |metadata|
      metadata[:attempt_openapi_generation] = true
    end

    config.after(:example, :attempt_openapi_generation) do |example|
      OpenApiGenerator.generate(self, example)
    end

    config.after(:suite) do
      result_recorder = RSpec::OpenAPI::ResultRecorder.new(RSpec::OpenAPI.path_records)
      result_recorder.record_results!
      if result_recorder.errors?
        error_message = result_recorder.error_message
        colorizer = RSpec::Core::Formatters::ConsoleCodes
        RSpec.configuration.reporter.message colorizer.wrap(error_message, :failure)
      end
    end
  end

  config.around do |example|
    Rails.logger.info "STARTING SPEC #{example.full_description}"
    SpecTimeLimit.enforce(example, &example)
  end

  def reset_all_the_things!
    LocalCache.reset
    ReadOnlySecondaryStub.reset
    Time.zone = "UTC"
    LoadAccount.force_special_account_reload = true
    Account.clear_special_account_cache!(true)
    PluginSetting.current_account = nil
    AdheresToPolicy::Cache.clear
    Setting.reset_cache!
    HostUrl.reset_cache!
    Notification.reset_cache!
    ActiveRecord::Base.reset_any_instantiation!
    Folder.reset_path_lookups!
    Rails.logger.try(:info, "Running #{self.class.description} #{@method_name}")
    Attachment.current_root_account = nil
    DynamicSettings.reset_cache!
    ActiveRecord::Migration.verbose = false
    RequestStore.clear!
    MultiCache.reset
    Course.enroll_user_call_count = 0
    TermsOfService.skip_automatic_terms_creation = true
    LiveEvents.clear_context!
    $spec_api_tokens = {}

    remove_user_session
  end

  Notification.after_create do
    Notification.reset_cache!
    BroadcastPolicy.notification_finder.refresh_cache
  end

  # UTC for tests, cuz it's easier :P
  Account.time_zone_attribute_defaults[:default_time_zone] = "UTC"

  config.before :all do
    raise "all specs need to use transactions" unless using_transactions_properly?
  end

  Onceler.configure do |c|
    c.before :record do
      reset_all_the_things!
      Canvas::DynamoDB::DatabaseBuilder.reset
    end
  end

  config.before do
    raise "all specs need to use transactions" unless using_transactions_properly?

    reset_all_the_things!
  end

  # normally all specs should always use transactions; you can override
  # this in a specific example group if you need to do something fancy/
  # crazy/slow. but you probably don't. seriously. just use once-ler
  def using_transactions_properly?
    use_transactional_tests
  end

  config.before :suite do
    if ENV["COVERAGE"] == "1"
      simple_cov_cmd = "rspec:#{Process.pid}"
      puts "Starting SimpleCov command: #{simple_cov_cmd}"
      SimpleCov.command_name(simple_cov_cmd)
      SimpleCov.pid = Process.pid # because https://github.com/colszowka/simplecov/pull/377
    end

    Timecop.safe_mode = true

    # cache brand variables because if we try to look them up inside a Timecop
    # block, we will conflict our active record patch to prevent future
    # migrations.
    BrandableCSS.default_variables_md5
  end

  config.before do
    allow(AttachmentFu::Backends::S3Backend).to receive(:load_s3_config) { StubS3::AWS_CONFIG.dup }
    allow(Canvas::Vault).to receive(:read) { StubVault::AWS_CONFIG.dup }
  end

  # flush redis before the first spec, and before each spec that comes after
  # one that used redis
  module TrackRedisUsage
    def self.prepended(klass)
      klass.send(:attr_accessor, :redis_used)
    end

    def redis(*)
      self.redis_used = true
      super
    end
  end
  CanvasCache::Redis.singleton_class.prepend(TrackRedisUsage)
  CanvasCache::Redis.redis_used = true

  config.before do
    if CanvasCache::Redis.enabled? && CanvasCache::Redis.redis_used
      # yes, we really mean to run this dangerous redis command
      GuardRail.activate(:deploy) { CanvasCache::Redis.redis.flushdb(failsafe: nil) }
    end
    CanvasCache::Redis.redis_used = false
  end

  if Canvas::Plugin.value_to_boolean(ENV["N_PLUS_ONE_DETECTION"])
    config.before do
      Prosopite.scan
    end

    config.after do
      Prosopite.finish
    end
  end

  # ****************************************************************
  # There used to be a lot of factory methods here!
  # In an effort to move us toward a nicer test factory solution,
  # all factories should now live in a separate file named to
  # correspond with the model that should be built by the factory.
  # Please see spec/factories for examples!
  # ****************************************************************

  def login_as(username = "nobody@example.com", password = "asdfasdf")
    post "/login/canvas",
         params: { "pseudonym_session[unique_id]" => username,
                   "pseudonym_session[password]" => password }
    follow_redirect! while response.redirect?
    assert_response :success
    expect(request.fullpath).to eq "/?login_success=1"
  end

  # Instead of directly comparing urls
  # this will make sure urls match
  # by parsing them, and comparing the results
  # meaning these would match
  #   http://test.dev/?foo=bar&other=1
  #   http://test.dev/?other=1&foo=bar
  def assert_url_parse_match(test_url, expected_url)
    parsed_test = URI.parse(test_url)
    parsed_expected = URI.parse(expected_url)

    parsed_test_query = Rack::Utils.parse_nested_query(parsed_test.query)
    parsed_expected_query = Rack::Utils.parse_nested_query(parsed_expected.query)

    expect(parsed_test.scheme).to eq parsed_expected.scheme
    expect(parsed_test.host).to eq parsed_expected.host
    expect(parsed_test_query).to eq parsed_expected_query
  end

  def assert_hash_contains(test_hash, expected_hash)
    expected_hash.each do |key, expected_value|
      expect(test_hash[key]).to eq expected_value
    end
  end

  def fixture_file_upload(path, mime_type = nil, binary = false)
    Rack::Test::UploadedFile.new(file_fixture(path), mime_type, binary)
  end

  def default_uploaded_data
    fixture_file_upload("docs/doc.doc", "application/msword", true)
  end

  def create_temp_dir!
    dir = Dir.mktmpdir
    @temp_dirs ||= []
    @temp_dirs << dir
    dir
  end

  def generate_csv_file(lines)
    tmp = Tempfile.new("sis_rspec")
    path = "#{tmp.path}.csv"
    tmp.close!
    File.open(path, "w+") { |f| f.puts lines.flatten.join "\n" }
    path
  end

  def process_csv_data(*lines)
    opts = lines.extract_options!
    opts.reverse_merge!(allow_printing: false)
    account = opts[:account] || @account || account_model
    user = opts[:user] || @user || user_model
    opts[:batch] ||= account.sis_batches.create!(user_id: user.id)

    path = generate_csv_file(lines)
    opts[:files] = [path]

    importer = SIS::CSV::ImportRefactored.process(account, opts)
    run_jobs

    File.unlink path

    importer
  end

  def process_csv_data_cleanly(*lines_or_opts)
    importer = process_csv_data(*lines_or_opts)
    raise "csv errors: #{importer.errors.inspect}" if importer.errors.present?

    importer
  end

  def set_cache(new_cache)
    cache_opts = {}
    if new_cache == :redis_cache_store
      if CanvasCache::Redis.enabled?
        cache_opts[:redis] = CanvasCache::Redis.redis
      else
        skip "redis required"
      end
    elsif new_cache == :memory_store
      cache_opts[:coder] = Marshal
    end
    new_cache ||= :null_store
    new_cache = ActiveSupport::Cache.lookup_store(new_cache, cache_opts)
    allow(Rails).to receive(:cache).and_return(new_cache)
    allow(ActionController::Base).to receive_messages(cache_store: new_cache, perform_caching: true)
    allow_any_instance_of(ActionController::Base).to receive(:cache_store).and_return(new_cache)
    allow_any_instance_of(ActionController::Base).to receive(:perform_caching).and_return(true)
    allow(MultiCache).to receive(:cache).and_return(new_cache)
  end

  def specs_require_cache(new_cache = :memory_store)
    before do
      set_cache(new_cache)
    end
  end

  def enable_cache(new_cache = :memory_store)
    previous_cache = Rails.cache
    previous_perform_caching = ActionController::Base.perform_caching
    previous_multicache = MultiCache.cache
    set_cache(new_cache)
    if block_given?
      begin
        yield
      ensure
        allow(Rails).to receive(:cache).and_return(previous_cache)
        allow(ActionController::Base).to receive_messages(cache_store: previous_cache, perform_caching: previous_perform_caching)
        allow_any_instance_of(ActionController::Base).to receive(:cache_store).and_return(previous_cache)
        allow_any_instance_of(ActionController::Base).to receive(:perform_caching).and_return(previous_perform_caching)
        allow(MultiCache).to receive(:cache).and_return(previous_multicache)
      end
    end
  end

  # enforce forgery protection, so we can verify usage of the authenticity token
  def enable_forgery_protection(enable = true)
    old_value = ActionController::Base.allow_forgery_protection
    allow(ActionController::Base).to receive(:allow_forgery_protection).and_return(enable)
    allow_any_instance_of(ActionController::Base).to receive(:allow_forgery_protection).and_return(enable)

    yield if block_given?
  ensure
    if block_given?
      allow(ActionController::Base).to receive(:allow_forgery_protection).and_return(old_value)
      allow_any_instance_of(ActionController::Base).to receive(:allow_forgery_protection).and_return(old_value)
    end
  end

  def stub_kaltura
    # trick kaltura into being activated
    allow(CanvasKaltura.plugin_settings).to receive(:settings).and_return({
                                                                            "domain" => "kaltura.example.com",
                                                                            "resource_domain" => "cdn.kaltura.example.com",
                                                                            "rtmp_domain" => "rtmp.kaltura.example.com",
                                                                            "partner_id" => "100",
                                                                            "subpartner_id" => "10000",
                                                                            "secret_key" => "fenwl1n23k4123lk4hl321jh4kl321j4kl32j14kl321",
                                                                            "user_secret_key" => "1234821hrj3k21hjk4j3kl21j4kl321j4kl3j21kl4j3k2l1",
                                                                            "player_ui_conf" => "1",
                                                                            "kcw_ui_conf" => "1",
                                                                            "upload_ui_conf" => "1",
                                                                            "hide_rte_button" => false
                                                                          })
  end

  def override_dynamic_settings(data)
    original_fallback = DynamicSettings.fallback_data
    DynamicSettings.fallback_data = data
    yield
  ensure
    DynamicSettings.fallback_data = original_fallback
  end

  def json_parse(json_string = response.body)
    JSON.parse(json_string)
  end

  # inspired by http://blog.jayfields.com/2007/08/ruby-calling-methods-of-specific.html
  module AttachmentStorageSwitcher
    BACKENDS = %w[FileSystem S3].map { |backend| AttachmentFu::Backends.const_get(:"#{backend}Backend") }.freeze

    class As # :nodoc:
      private(*instance_methods.grep_v(/(^__|^\W|^binding$|^untaint$)/)) # rubocop:disable Style/AccessModifierDeclarations

      def initialize(subject, ancestor)
        @subject = subject
        @ancestor = ancestor
      end

      def method_missing(sym, ...)
        @ancestor.instance_method(sym).bind_call(@subject, ...)
      end
    end

    def self.included(base)
      base.cattr_accessor :current_backend
      base.current_backend = (base.ancestors & BACKENDS).first

      # make sure we have all the backends
      BACKENDS.each do |backend|
        base.include(backend) unless base.ancestors.include?(backend)
      end
      # remove the duplicate callbacks added by multiple backends
      base.before_update.uniq!

      BACKENDS.map(&:instance_methods).flatten.uniq.each do |method|
        # overridden by Attachment anyway; don't re-overwrite it
        next if base.instance_method(method).owner == base

        if method.to_s[-1..] == "="
          base.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method}(arg)
              self.as(self.class.current_backend).#{method} arg
            end
          RUBY
        else
          base.class_eval <<~RUBY, __FILE__, __LINE__ + 1
            def #{method}(*args, &block)
              self.as(self.class.current_backend).#{method}(*args, &block)
            end
          RUBY
        end
      end
    end

    def as(ancestor)
      @__as ||= {}
      unless (r = @__as[ancestor])
        r = (@__as[ancestor] = As.new(self, ancestor))
      end
      r
    end
  end

  module StubS3
    AWS_CONFIG = {
      access_key_id: "stub_id",
      secret_access_key: "stub_key",
      credentials: Aws::Credentials.new("stub_id", "stub_key"),
      region: "us-east-1",
      stub_responses: true,
      bucket_name: "no-bucket"
    }.freeze

    def self.stubbed?
      false
    end

    def load(file, *args)
      return AWS_CONFIG.dup if StubS3.stubbed? && file == "amazon_s3"

      super
    end
  end

  module StubVault
    AWS_CONFIG = {
      access_key: "stub_access_key",
      secret_key: "stub_secret_key",
      security_token: "stub_security_token"
    }.freeze
  end

  def s3_storage!(opts = { stubs: true })
    [Attachment, Thumbnail].each do |model|
      model.include(AttachmentStorageSwitcher) unless model.ancestors.include?(AttachmentStorageSwitcher)
      allow(model).to receive_messages(current_backend: AttachmentFu::Backends::S3Backend,
                                       s3_storage?: true,
                                       local_storage?: false)
    end

    if opts[:stubs]
      ConfigFile.singleton_class.prepend(StubS3)
      allow(StubS3).to receive(:stubbed?).and_return(true)
    elsif Attachment.s3_config.blank? || Attachment.s3_config[:access_key_id] == "access_key"
      skip "Please put valid S3 credentials in config/amazon_s3.yml"
    end
  end

  def local_storage!
    [Attachment, Thumbnail].each do |model|
      model.include(AttachmentStorageSwitcher) unless model.ancestors.include?(AttachmentStorageSwitcher)
      allow(model).to receive_messages(current_backend: AttachmentFu::Backends::FileSystemBackend,
                                       s3_storage?: false,
                                       local_storage?: true)
    end
  end

  def run_job(job)
    Delayed::Testing.run_job(job)
  end

  def run_jobs
    Delayed::Testing.drain
  end

  def track_jobs(&)
    @jobs_tracking = Delayed::JobTracking.track(&)
  end

  def created_jobs
    @jobs_tracking.created
  end

  def expects_job_with_tag(tag, count = 1, &)
    track_jobs(&)
    expect(created_jobs.count { |j| j.tag == tag }).to eq count
  end

  def content_type_key
    "Content-Type"
  end

  class FakeHttpResponse
    def initialize(code, body = nil, headers = {})
      @code = code
      @body = body
      @headers = headers
    end

    def read_body(io = nil)
      return yield(@body) if block_given?
      return if io.nil?

      io << @body
    end

    def code
      @code.to_s
    end

    def [](arg)
      @headers[arg]
    end

    def content_type
      self["content-type"]
    end
  end

  # frd class, not a mock, so we can once-ler WebConferences (need to Marshal.dump)
  class WebConferencePluginMock
    attr_reader :id, :settings

    def initialize(id, settings)
      @id = id
      @settings = settings
    end

    def valid_settings?
      true
    end

    def enabled?
      true
    end

    def base; end

    def name
      id.to_s.humanize
    end
  end

  def web_conference_plugin_mock(id, settings)
    WebConferencePluginMock.new(id, settings)
  end

  def dummy_io
    fixture_file_upload("docs/doc.doc", "application/msword", true)
  end

  def consider_all_requests_local(value)
    old_value = Rails.application.config.consider_all_requests_local
    Rails.application.config.consider_all_requests_local = value
    yield
  ensure
    Rails.application.config.consider_all_requests_local = old_value
  end

  def skip_if_prepended_class_method_stubs_broken
    versions = [
      "2.4.6",
      "2.4.9",
      "2.5.1",
      "2.5.3"
    ]
    skip("stubbing prepended class methods is broken in this version of ruby") if versions.include?(RUBY_VERSION) || RUBY_VERSION >= "2.6"
  end
end

module I18nStubs
  def stub(translations)
    new_locales = translations.keys - I18n.config.available_locales
    @stubs = translations.with_indifferent_access
    unless new_locales.empty?
      I18n.config.available_locales = I18n.config.available_locales + new_locales
    end
    yield
  ensure
    @stubs = nil
    unless new_locales.empty?
      I18n.config.available_locales = I18n.config.available_locales - new_locales
    end
  end

  def lookup(locale, key, scope = [], options = {})
    return super unless @stubs

    init_translations unless initialized?
    keys = I18n.normalize_keys(locale, key, scope, options[:separator])
    keys.inject(@stubs) { |h, k| h[k] if h.respond_to?(:key) } || super
  end

  def available_locales
    return super unless @stubs

    super | @stubs.keys.map(&:to_sym)
  end
end
I18n.backend.class.prepend(I18nStubs)

Dir[Rails.root.join("{gems,vendor}/plugins/*/spec_canvas/spec_helper.rb")].each { |file| require file }

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :active_record
    with.library :active_model
    # Disable the action_controller matchers until shoulda-matchers supports new compound matchers
    # with.library :action_controller
    # Or, choose the following (which implies all of the above):
    # with.library :rails
  end
end

module DeveloperKeyStubs
  def get_special_key(default_key_name)
    Shard.birth.activate do
      @special_keys ||= {}

      # TODO: we have to do this because tests run in transactions
      testkey = DeveloperKey.where(name: default_key_name).first_or_initialize
      testkey.auto_expire_tokens = false if testkey.new_record?
      testkey.sns_arn = "arn:aws:s3:us-east-1:12345678910:foo/bar"
      testkey.save! if testkey.changed?
      return @special_keys[default_key_name] = testkey
    end
  end
end
DeveloperKey.singleton_class.prepend DeveloperKeyStubs

def enable_developer_key_account_binding!(developer_key)
  developer_key.developer_key_account_bindings.first.update!(
    workflow_state: "on"
  )
end

def disable_developer_key_account_binding!(developer_key)
  developer_key.developer_key_account_bindings.first.update!(
    workflow_state: "off"
  )
end

def enable_default_developer_key!
  enable_developer_key_account_binding!(DeveloperKey.default)
end

# register mime types for their responses being decoded as JSON
Mime::SET.select { |t| t.to_s.end_with?("+json") }.map(&:ref).each do |type|
  ActionDispatch::RequestEncoder.register_encoder(type,
                                                  response_parser: ->(body) { JSON.parse(body) })
end

# rubocop:enable Lint/ConstantDefinitionInBlock
