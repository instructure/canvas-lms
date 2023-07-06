# frozen_string_literal: true

#
# Copyright (C) 2021 - present Instructure, Inc.
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

# This is a dynamo single-table backed model
# Schema documentation:
# All records have a PartitionKey and a RangeKey, and optionally additional fields named appropriately for the record
# type.  There are the following types with the following schemas:
# | Type | Notes | PartitionKey | RangeKey |
# |--|--|--|--|--|
# | All ids | used to list notes for the index | `all_notes` | `{created_at}|{id}` |
# | Note release times | powers the sidebar recent notes | `{env}_release|{role}` | `{release_time}|{id}` |
# | Release note | Authoritative copy of record | `{id}` | `info` |
# | Release note translation | translated resource for a single locale | `{id}` | `lang|{code}` |
#
# The first three types all have the same additional fields:
# * `Id` (String)
# * `Published` (boolean)
# * `ShowAts` (map of times to show notes, per env)
# * `TargetRoles` (list of roles to view note)
# * `CreatedAt` (creation timestamp)
# Release note translation additional fields:
# * `Title` (string)
# * `Description` (string)
# * `Url` (string)

class ReleaseNote
  include ActiveModel::Dirty
  include ActiveModel::Serializers::JSON

  attr_reader :id, :published, :created_at

  define_attribute_methods :id, :show_ats, :target_roles, :published

  def initialize(ddb_item = nil)
    @langs = {}
    @target_roles = []
    @show_ats = {}
    @published = false
    @created_at = nil
    return if ddb_item.nil?

    @id = ddb_item["Id"]
    @show_ats = ddb_item["ShowAts"].transform_values { |v| Time.parse(v).utc }
    @target_roles = ddb_item["TargetRoles"]
    @published = ddb_item["Published"]
    @created_at = Time.parse(ddb_item["CreatedAt"]).utc
  end

  def attributes
    { "id" => nil, "show_ats" => nil, "target_roles" => nil, "published" => nil, "langs" => nil }
  end

  def target_roles
    @target_roles.freeze
  end

  def target_roles=(new_roles)
    target_roles_will_change! unless new_roles == @target_roles
    @target_roles = new_roles
  end

  def published=(new_published)
    published_will_change! unless new_published == @published
    @published = new_published
  end

  def show_ats
    @show_ats.dup.freeze
  end

  def set_show_at(env, time)
    show_ats_will_change!
    @show_ats[env] = time
  end

  def save
    @id ||= SecureRandom.uuid
    @created_at ||= Time.now.utc
    common_attributes = {
      "Id" => id,
      "ShowAts" => show_ats.transform_values { |v| v.utc.iso8601 },
      "TargetRoles" => target_roles,
      "Published" => published,
      "CreatedAt" => created_at.utc.iso8601

    }
    payload = [
      {
        put_request: {
          item: {
            "PartitionKey" => id,
            "RangeKey" => "info"
          }.merge(common_attributes)
        }
      },
      {
        put_request: {
          item: {
            "PartitionKey" => "all_notes",
            "RangeKey" => "#{created_at.utc.iso8601}|#{id}"
          }.merge(common_attributes)
        }
      }
    ]
    payload += @langs.map do |lang, translations|
      {
        put_request: {
          item: {
            "PartitionKey" => id,
            "RangeKey" => "lang|#{lang}",
            "Title" => translations[:title],
            "Description" => translations[:description],
            "Url" => translations[:url]
          }
        }
      }
    end
    current_values = published ? show_ats.to_a.product(target_roles) : []
    old_values = published_was ? show_ats_was.to_a.product(target_roles_was) : []
    payload += current_values.map do |pair|
      env = pair[0]
      role = pair[1]
      {
        put_request: {
          item: {
            "PartitionKey" => "#{env[0]}_release|#{role}",
            "RangeKey" => "#{env[1].iso8601}|#{id}"
          }.merge(common_attributes)
        }
      }
    end
    to_delete = old_values - current_values
    payload += to_delete.map do |pair|
      env = pair[0]
      role = pair[1]
      {
        delete_request: {
          key: {
            "PartitionKey" => "#{env[0]}_release|#{role}",
            "RangeKey" => "#{env[1].iso8601}|#{id}"
          }
        }
      }
    end
    self.class.ddb_client.batch_write_item(
      request_items: { self.class.ddb_table_name => payload }
    )
    changes_applied
  end

  def delete
    load_all_langs
    payload = [
      {
        delete_request: {
          key: {
            "PartitionKey" => id,
            "RangeKey" => "info"
          }
        }
      },
      {
        delete_request: {
          key: {
            "PartitionKey" => "all_notes",
            "RangeKey" => "#{created_at.utc.iso8601}|#{id}"
          }
        }
      }
    ]
    payload += @langs.map do |lang, _translations|
      {
        delete_request: {
          key: {
            "PartitionKey" => id,
            "RangeKey" => "lang|#{lang}"
          }
        }
      }
    end
    current_values = show_ats.to_a.product(target_roles)
    payload += current_values.map do |pair|
      env = pair[0]
      role = pair[1]
      {
        delete_request: {
          key: {
            "PartitionKey" => "#{env[0]}_release|#{role}",
            "RangeKey" => "#{env[1].iso8601}|#{id}"
          }
        }
      }
    end
    self.class.ddb_client.batch_write_item(
      request_items: { self.class.ddb_table_name => payload }
    )
    changes_applied
  end

  def [](lang)
    @langs[lang] ||= fetch_i18n(lang)
  end

  def []=(lang, translations)
    @langs[lang] = translations
  end

  def langs
    load_all_langs
    @langs
  end

  private

  def load_all_langs
    return if @all_langs_loaded

    res = self.class.ddb_client.query(
      expression_attribute_values: {
        ":id" => id,
        ":sort" => "lang|",
      },
      key_condition_expression: "PartitionKey = :id AND begins_with(RangeKey, :sort)",
      table_name: self.class.ddb_table_name
    )
    res.items.each do |translations|
      lang = translations["RangeKey"].split("|")[1]
      @langs[lang] ||= {
        title: translations["Title"],
        description: translations["Description"],
        url: translations["Url"]
      }
    end

    @all_langs_loaded = true
  end

  def fetch_i18n(lang)
    res = self.class.ddb_client.query(
      expression_attribute_values: {
        ":id" => id,
        ":sort" => "lang|#{lang}",
      },
      key_condition_expression: "PartitionKey = :id AND RangeKey = :sort",
      table_name: self.class.ddb_table_name
    )
    return nil unless res.items.length.positive?

    translations = res.items.first
    {
      title: translations["Title"],
      description: translations["Description"],
      url: translations["Url"]
    }
  end

  def to_hash
    {
      id:,
      show_ats:,
      target_roles:,
      published:,
      langs: @langs
    }
  end

  class << self
    def find(ids, include_langs: false)
      ids_arr = Array.wrap(ids)
      return [] if ids_arr.empty?

      res = ddb_client.batch_get_item(request_items: { ddb_table_name => {
                                        keys: ids_arr.map do |id|
                                          {
                                            PartitionKey: id,
                                            RangeKey: "info"
                                          }
                                        end
                                      } })

      raise ActiveRecord::RecordNotFound unless res.responses[ddb_table_name].length == ids_arr.length

      ret = load_raw_records(res.responses[ddb_table_name], include_langs:)
      ids.is_a?(Array) ? ret.sort_by { |note| ids_arr.index(note.id) } : ret.first
    end

    def paginated(include_langs: false)
      BookmarkedCollection.build(Bookmarker) do |pager|
        start = nil
        if pager.current_bookmark
          start = { PartitionKey: "all_notes", RangeKey: pager.current_bookmark }
        end

        res = ddb_client.query(
          expression_attribute_values: {
            ":id" => "all_notes"
          },
          key_condition_expression: "PartitionKey = :id",
          table_name: ddb_table_name,
          limit: pager.per_page,
          scan_index_forward: false,
          exclusive_start_key: start
        )

        pager.replace(load_raw_records(res.items, include_langs:))
        pager.has_more! unless res.last_evaluated_key.nil?
        pager
      end
    end

    def latest(env:, role:, limit: 10)
      res = ddb_client.query(
        expression_attribute_values: {
          ":id" => "#{env}_release|#{role}",
          ":sort" => Time.now.utc.iso8601,
        },
        key_condition_expression: "PartitionKey = :id AND RangeKey <= :sort",
        table_name: ddb_table_name,
        limit:,
        scan_index_forward: false
      )
      load_raw_records(res.items)
    end

    def load_raw_records(records, include_langs: false)
      ret = records.map { |it| ReleaseNote.new(it) }
      ret.each { |it| it.send(:load_all_langs) } if include_langs

      ret
    end

    def enabled?
      !ddb_table_name.nil?
    end

    def settings
      YAML.safe_load(DynamicSettings.find(tree: :private)["release_notes.yml", failsafe: "{}"] || "{}")
    end

    def ddb_table_name
      settings["ddb_table_name"]
    end

    def ddb_client
      @ddb_client ||= begin
        config = {
          region: settings["ddb_region"] || "us-east-1"
        }
        config[:endpoint] = settings["ddb_endpoint"] if settings["ddb_endpoint"]
        config[:credentials] = Canvas::AwsCredentialProvider.new("release_notes_creds", settings["vault_credential_path"])
        aws_client = Aws::DynamoDB::Client.new(config)
        CanvasDynamoDB::Database.new("release_notes:#{Rails.env}", client_opts: { client: aws_client }, logger: Rails.logger)
      end
    end

    def reset!
      # if we reload everything, we don't want a cached
      # ddb client with old settings
      @ddb = nil
    end
  end
  Canvas::Reloader.on_reload { reset! }

  module Bookmarker
    def self.bookmark_for(note)
      "#{note.created_at.utc.iso8601}|#{note.id}"
    end

    def self.validate(bookmark)
      bookmark.is_a?(String)
    end
  end
end
