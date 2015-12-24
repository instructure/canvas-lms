require 'net/http'

require 'cgi'

require 'academic_benchmark_v1'

require 'academic_benchmark/engine'
require 'academic_benchmark/cli_tools'

require 'academic_benchmark/ab_gem_extensions/standard'
require 'academic_benchmark/ab_gem_extensions/authority'
require 'academic_benchmark/ab_gem_extensions/document'

require 'academic_benchmark/outcome_data'
require 'academic_benchmark/outcome_data/from_api'
require 'academic_benchmark/outcome_data/from_file'


module AcademicBenchmark
  NATIONAL_STANDARDS_TITLE = "National Standards".freeze
  NATIONAL_STD_CODES = %w[CC NT NRC].freeze
  COUNTRY_STD_CODES = %w[AU UK].freeze
  UNITED_KINGDOM_TITLE = "United Kingdom".freeze
  COMMON_CORE_AUTHORITY = 'CC'.freeze
  NGSS_AUTHORITY = 'NRC'.freeze

  def self.config
    empty_settings = {}.freeze
    p = Canvas::Plugin.find('academic_benchmark_importer')
    return empty_settings unless p
    p.settings || empty_settings
  end

  def self.check_config
    if self.v3?
      self.check_v3_config
    else
      self.check_v1_config
    end
  end

  def self.check_v3_config
    if !self.config
      "(needs partner_key and partner_id)"
    elsif !self.config[:partner_key].present?
      "(needs partner_key)"
    elsif !self.config[:partner_id].present?
      "(needs partner_id)"
    end
  end

  def self.check_v1_config
    if !self.config
      "(needs api_key and api_url)"
    elsif !self.config["api_key"] || self.config["api_key"].empty?
      "(needs api_key)"
    elsif !self.config["api_url"] || self.config["api_url"].empty?
      "(needs api_url)"
    end
  end

  def self.v3?
    self.config.present? && self.config[:partner_key].present?
  end

  def self.extract_nat_stds(api, nat_stds_guid)
    return [] if nat_stds_guid.nil?
    if AcademicBenchmark.v3?
      api.standards.authority_documents(nat_stds_guid)
    else
      api.browse_guid(nat_stds_guid).first["itm"].first["itm"]
    end
  end

  ##
  # Extract the national standards from the list of authorities
  # National Standards are also known as Common Core and NGSS
  ##
  def self.nat_stds_guid_from_auths(authorities)
    if AcademicBenchmark.v3?
      stds = authorities.find{|a| a.description == NATIONAL_STANDARDS_TITLE}
      stds.try(:guid)
    else
      authorities.find{|a| a["title"] == NATIONAL_STANDARDS_TITLE}["guid"]
    end
  end

  ##
  # get a list of all of the available authorities,
  # and sort them alphabetically by title.
  #
  # Academic Benchmarks authorities are generally State Standards,
  # although "National Standards" is an authority which must be
  # browsed in order to retrieve specifics like NGSS and Common Core
  ##
  def self.retrieve_authorities(api)
    if AcademicBenchmark.v3?
      self.sort_authorities(api.standards.authorities)
    else
      authorities = api.list_available_authorities.select { |a| a.key?("title") }
      authorities.sort_by {|b| b["title"]}
    end
  end

  # sort national standards at the top, followed by country standards,
  # followed by the rest at the bottom in alphabetical order
  def self.sort_authorities(authorities)
    national_stds, rest = authorities.partition{ |a| NATIONAL_STD_CODES.include?(a.code) }
    country_stds, rest = rest.partition{ |a| COUNTRY_STD_CODES.include?(a.code) }
    [
      self.sort_authorities_by_description(national_stds),
      self.sort_authorities_by_description(country_stds),
      self.sort_authorities_by_description(rest)
    ].flatten
  end

  def self.sort_authorities_by_description(authorities)
    authorities.sort_by(&:description)
  end

  ##
  # Get a list of all of the available guids that users can import.
  # These can be passed to the `create` action
  ##
  def self.list_of_available_guids
    api = self.api_handle
    auth_list = self.retrieve_authorities(api)

    # prepend the common core, next gen science standards,
    # and the ISTE (NETS) standards to the list
    auth_list.unshift(self.extract_nat_stds(api, self.nat_stds_guid_from_auths(auth_list)))
    if self.v3?
      auth_list.unshift(api.standards.authority_documents(NGSS_AUTHORITY))
      auth_list.unshift(api.standards.authority_documents(COMMON_CORE_AUTHORITY))

      # flatten down the list of authorities and hashify it
      auth_list.flatten!
      auth_list.map(&:to_h)
    else
      # append the UK standards to the end of the list and flatten it down
      auth_list.push(self.uk_guid(api)).flatten
    end
  end

  # The UK standards are now available to us as well,
  def self.uk_guid(api)
    api.browse.find{ |a| a["title"] == UNITED_KINGDOM_TITLE }
  end

  class APIError < StandardError; end

  def self.import(guid, options = {})
    if self.v3?
      is_auth = self.auth?(guid)
      authority = is_auth ? guid : nil
      document = is_auth ? nil : guid
      check_args(authority, document)
      self.ensure_ab_credentials

      AcademicBenchmark.queue_migration_for(
        authority: authority,
        document: document,
        user: self.authorized?,
        options: options
      ).first
    else
      AcademicBenchmarkV1.import(Array(guid), options).first
    end
  end

  def self.queue_migration_for(authority:, document:, user:, options: {})
    cm = ContentMigration.new(context: Account.site_admin)
    cm.converter_class = self.config['converter_class']
    cm.migration_settings[:migration_type] = 'academic_benchmark_importer'
    cm.migration_settings[:import_immediately] = true
    cm.migration_settings[:authority] = authority
    cm.migration_settings[:document] = document
    cm.migration_settings[:no_archive_file] = true
    cm.migration_settings[:skip_import_notification] = true
    cm.migration_settings[:skip_job_progress] = true
    cm.migration_settings[:migration_options] = options
    cm.strand = "academic_benchmark"
    cm.user = user
    cm.save!
    [cm, cm.export_content]
  end

  def self.set_common_core_setting!
    unless self.v3?
      AcademicBenchmarkV1.set_common_core_setting!
    end
  end

  def self.common_core_setting_key
    unless self.v3?
      AcademicBenchmarkV1.common_core_setting_key
    end
  end

  def self.api_handle
    # create a new api connection.  Note that this does not actually
    # make a request to the API
    if AcademicBenchmark.v3?
      AcademicBenchmarks::Api::Handle.new(partner_id: config[:partner_id], partner_key: config[:partner_key])
    else
      AcademicBenchmark::Api.new(self.config["api_key"], base_url: self.config["api_url"])
    end
  end

  private

  def self.auth?(guid)
    self.api_handle.standards.authorities.map(&:guid).include?(guid)
  end

  def self.check_args(authority, document)
    if authority.nil? && document.nil?
      raise Canvas::Migration::Error,
        "You must specify either an Authority or a Document to import (both were nil)"
    end
  end

  def self.ensure_ab_credentials
    err = nil
    err ||= self.ensure_partner_id
    err ||= self.ensure_partner_key
    if err
      raise Canvas::Migration::Error,
        "Not importing academic benchmark data because the Academic Benchmarks #{err}"
    end
  end

  def self.ensure_partner_id
    unless AcademicBenchmark.config[:partner_id].present?
      return "Partner ID is not set"
    end
  end

  def self.ensure_partner_key
    unless AcademicBenchmark.config[:partner_key].present?
      return "Partner key is not set"
    end
  end

  def self.authorized?
    self.check_for_import_rights(
      user: self.ensure_real_user(user_id: self.ensure_user_id_set)
    )
  end

  def self.ensure_user_id_set
    uid = Setting.get("academic_benchmark_migration_user_id", nil)
    unless uid.present?
      raise Canvas::Migration::Error,
        'Not importing academic benchmark data because no user id set'
    end
    uid
  end

  def self.ensure_real_user(user_id:)
    u = User.find_by(id: user_id)
    unless u
      raise Canvas::Migration::Error,
        "Not importing academic benchmark data because no user found matching id '#{user_id}'"
    end
    u
  end

  def self.check_for_import_rights(user:)
    unless Account.site_admin.grants_right?(user, :manage_global_outcomes)
      raise Canvas::Migration::Error,
        "Not importing academic benchmark data because user with ID " \
        "'#{user.id}' isn't allowed to edit global outcomes"
    end
    user
  end
end
