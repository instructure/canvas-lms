
RSpec.configure do |config|
  config.include Capybara::DSL,          type: :controller
  config.include FeatureHelpers,         type: :feature
  config.include FeatureJsHelpers,       type: :feature
  config.include GeneralHelpers

  config.include FactoryBot::Syntax::Methods
  config.include ActionView::Helpers::TextHelper

  # This has to be included before SeleniumDependencies or some Factory methods with same names
  # as in Selenium modules will get overridden incorrectly
  config.include Factories # Canvas LMS factories in /spec, not factory girl
  config.include SeleniumDependencies,   type: :feature

  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!

  def reset_all_the_things!
    I18n.locale = :en
    Time.zone = 'Arizona'
    LoadAccount.force_special_account_reload = true
    Account.clear_special_account_cache!(true)
    PluginSetting.current_account = nil
    AdheresToPolicy::Cache.clear
    Setting.reset_cache!
    HostUrl.reset_cache!
    Notification.reset_cache!
    # ActiveRecord::Base.reset_any_instantiation!
    Folder.reset_path_lookups!
    RoleOverride.clear_cached_contexts
    Delayed::Job.redis.flushdb if Delayed::Job == Delayed::Backend::Redis::Job
    Rails::logger.try(:info, "Running #{self.class.description} #{@method_name}")
    Attachment.domain_namespace = nil
    Canvas::DynamicSettings.reset_cache!
    ActiveRecord::Migration.verbose = false
    RequestStore.clear!
    Course.enroll_user_call_count = 0
    $spec_api_tokens = {}
  end

  Notification.after_create do
    Notification.reset_cache!
    BroadcastPolicy.notification_finder.refresh_cache
  end

  # Mirror canvas's specs
  Account.time_zone_attribute_defaults[:default_time_zone] = 'Arizona'

  config.before :all do
    Role.ensure_built_in_roles!
  end

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)

    begin
      DatabaseCleaner.start
    ensure
      DatabaseCleaner.clean
    end
  end

  config.before(:each) do
    reset_all_the_things!
    Delayed::Testing.clear_all! # delete all queued jobs

    DatabaseCleaner.strategy = Capybara.current_driver == :rack_test ? :transaction : :truncation
    DatabaseCleaner.start

    Role.ensure_built_in_roles!
  end

  config.after(:each) do
    Timecop.return
  end

  config.append_after(:each) do
    DatabaseCleaner.clean
  end

  config.after :suite do

  end

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")



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
      return if return_type == :nil
      scope = klass.order("id DESC").limit(records.size)
      return_type == :record ?
        scope.to_a.reverse :
        scope.pluck(:id).reverse
    end
  end
end
