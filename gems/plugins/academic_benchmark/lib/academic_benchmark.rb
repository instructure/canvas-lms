# frozen_string_literal: true

#
# Copyright (C) 2012 - present Instructure, Inc.
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

require "academic_benchmark/engine"

require "academic_benchmark/ab_gem_extensions/authority"
require "academic_benchmark/ab_gem_extensions/document"
require "academic_benchmark/ab_gem_extensions/publication"
require "academic_benchmark/ab_gem_extensions/section"
require "academic_benchmark/ab_gem_extensions/standard"

module AcademicBenchmark
  # The authorities have changed from v3 to v4.1, namely:
  # National Standards (NT) -> ISTE
  # NRC/NGSS -> Achieve
  # NGA Center/CCSSO -> CC

  COMMON_CORE_AUTHORITY = "CC"
  ISTE_AUTHORITY_CODE = "ISTE"
  ACHIEVE_AUTHORITY = "Achieve" # code: -none-
  NATIONAL_STDS = [COMMON_CORE_AUTHORITY, ISTE_AUTHORITY_CODE, ACHIEVE_AUTHORITY].freeze
  COUNTRY_STDS = [
    "Australian Curriculum, Assessment and Reporting Authority", # code: acara
    "UK Department for Education" # code: -none-
  ].freeze

  def self.config
    empty_settings = {}.freeze
    p = Canvas::Plugin.find("academic_benchmark_importer")
    return empty_settings unless p

    p.settings || empty_settings
  end

  def self.check_config
    if !config
      "(needs partner_key and partner_id)"
    elsif config[:partner_key].blank?
      "(needs partner_key)"
    elsif config[:partner_id].blank?
      "(needs partner_id)"
    end
  end

  def self.extract_nat_stds(api, nat_stds_guid)
    return [] if nat_stds_guid.nil?

    api.standards.authority_publications(nat_stds_guid)
  end

  ##
  # Extract the national standards from the list of authorities
  # National Standards are also known as Common Core and NGSS
  ##
  def self.nat_stds_guid_from_auths(authorities)
    stds = authorities.find { |a| a.code == ISTE_AUTHORITY_CODE }
    stds.try(:guid)
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
    sort_authorities(api.standards.authorities)
  end

  # sort national standards at the top, followed by country standards,
  # followed by the rest at the bottom in alphabetical order
  def self.sort_authorities(authorities)
    national_stds, rest = authorities.partition { |a| NATIONAL_STDS.include?(a.code) || NATIONAL_STDS.include?(a.description) }
    country_stds, rest = rest.partition { |a| COUNTRY_STDS.include?(a.description) }
    [
      sort_authorities_by_description(national_stds),
      sort_authorities_by_description(country_stds),
      sort_authorities_by_description(rest)
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
    api = api_handle
    auth_list = retrieve_authorities(api)

    # prepend the common core, next gen science standards (Achieve),
    # and the ISTE (NETS) standards to the list
    auth_list.unshift(extract_nat_stds(api, nat_stds_guid_from_auths(auth_list)))
    auth_list.unshift(api.standards.authority_publications(ACHIEVE_AUTHORITY))
    auth_list.unshift(api.standards.authority_publications(COMMON_CORE_AUTHORITY))

    # flatten down the list of authorities and hashify it
    auth_list.flatten!
    # exclude acronym (code) values since they're not unique across authorities/publications
    auth_list.map(&:to_h).map do |item|
      {
        title: item[:descr],
        guid: item[:guid]
      }
    end
  end

  class APIError < StandardError; end

  def self.import(guid, options = {})
    is_auth = auth?(guid)
    authority = is_auth ? guid : nil
    publication = is_auth ? nil : guid
    check_args(authority, publication)
    ensure_ab_credentials

    AcademicBenchmark.queue_migration_for(
      authority:,
      publication:,
      user: authorized?,
      options:
    ).first
  end

  def self.queue_migration_for(authority:, publication:, user:, options: {})
    cm = ContentMigration.new(context: Account.site_admin)
    cm.converter_class = config["converter_class"]
    cm.migration_settings[:migration_type] = "academic_benchmark_importer"
    cm.migration_settings[:import_immediately] = true
    cm.migration_settings[:authority] = authority
    cm.migration_settings[:publication] = publication
    cm.migration_settings[:no_archive_file] = true
    cm.migration_settings[:skip_import_notification] = true
    cm.migration_settings[:skip_job_progress] = true
    cm.migration_settings[:migration_options] = options
    cm.strand = "academic_benchmark"
    cm.user = user
    cm.root_account_id = 0
    cm.save!
    [cm, cm.export_content]
  end

  def self.api_handle
    # create a new api connection.  Note that this does not actually
    # make a request to the API
    AcademicBenchmarks::Api::Handle.new(partner_id: config[:partner_id], partner_key: config[:partner_key])
  end

  def self.auth?(guid)
    api_handle.standards.authorities.map(&:guid).include?(guid)
  end

  def self.check_args(authority, publication)
    if authority.nil? && publication.nil?
      raise Canvas::Migration::Error,
            "You must specify either an Authority or a Publication to import (both were nil)"
    end
  end

  def self.ensure_ab_credentials
    err = nil
    err ||= ensure_partner_id
    err ||= ensure_partner_key
    if err
      raise Canvas::Migration::Error,
            "Not importing academic benchmark data because the Academic Benchmarks #{err}"
    end
  end

  def self.ensure_partner_id
    unless AcademicBenchmark.config[:partner_id].present?
      "Partner ID is not set"
    end
  end

  def self.ensure_partner_key
    unless AcademicBenchmark.config[:partner_key].present?
      "Partner key is not set"
    end
  end

  def self.authorized?
    check_for_import_rights(
      user: ensure_real_user(user_id: ensure_user_id_set)
    )
  end

  def self.ensure_user_id_set
    uid = Setting.get("academic_benchmark_migration_user_id", nil)
    unless uid.present?
      raise Canvas::Migration::Error,
            "Not importing academic benchmark data because no user id set"
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
