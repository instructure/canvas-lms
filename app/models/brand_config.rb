# frozen_string_literal: true

#
# Copyright (C) 2015 - present Instructure, Inc.
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

class BrandConfig < ActiveRecord::Base
  include BrandableCSS

  self.primary_key = "md5"
  serialize :variables, type: Hash

  OVERRIDE_TYPES = %i[js_overrides css_overrides mobile_js_overrides mobile_css_overrides].freeze
  ATTRS_TO_INCLUDE_IN_MD5 = ([:variables, :parent_md5] + OVERRIDE_TYPES).freeze

  validates :variables, presence: true, unless: :overrides?
  validates :md5, length: { is: 32 }

  before_validation :generate_md5
  before_update do
    raise "BrandConfigs are a key-value mapping of config variables and an md5 digest " \
          "of those variables, so they are immutable. You do not update them, you just " \
          "save a new one and it will generate the new md5 for you"
  end

  after_save :clear_cache

  has_many :accounts, foreign_key: "brand_config_md5"
  has_many :shared_brand_configs, foreign_key: "brand_config_md5"

  # belongs_to :parent, class_name: "BrandConfig", foreign_key: "parent_md5"
  def parent
    return nil unless parent_md5

    BrandConfig.shard(parent_shard).find_by(md5: local_parent_md5)
  end

  def parent_shard
    parent_md5.include?("~") ? Shard.lookup(parent_md5.split("~")[0].to_i) : shard
  end

  def local_parent_md5
    parent_md5.split("~").last
  end

  def self.for(attrs)
    attrs = attrs.with_indifferent_access.slice(*ATTRS_TO_INCLUDE_IN_MD5)
    new_config = new(attrs)

    return default if new_config.default?

    new_config.parent_md5 = attrs[:parent_md5]
    existing_config = where(md5: new_config.generate_md5).first
    existing_config || new_config
  end

  def self.default
    new
  end

  MD5_OF_K12_CONFIG = "a1f113321fa024e7a14cb0948597a2a4"
  def self.k12_config
    find(MD5_OF_K12_CONFIG)
  end

  def self.cache_key_for_md5(shard_id, md5)
    ["brand_configs", shard_id, md5].cache_key
  end

  def self.find_cached_by_md5(shard_id, md5)
    MultiCache.fetch(cache_key_for_md5(shard_id, md5)) do
      BrandConfig.shard(Shard.lookup(shard_id)).find_by(md5:)
    end
  end

  def clear_cache
    shard.activate do
      self.class.connection.after_transaction_commit do
        MultiCache.delete(self.class.cache_key_for_md5(shard.id, md5))
      end
    end
  end

  def default?
    ([:variables] + OVERRIDE_TYPES).all? { |a| self[a].blank? }
  end

  def generate_md5
    self.id = BrandConfig.md5_for(self)
  end

  def self.md5_for(brand_config)
    Digest::MD5.hexdigest(ATTRS_TO_INCLUDE_IN_MD5.map { |a| brand_config[a] }.join)
  end

  def get_value(variable_name)
    effective_variables[variable_name]
  end

  def overrides?
    OVERRIDE_TYPES.any? { |o| self[o].present? }
  end

  def effective_variables
    @effective_variables ||=
      chain_of_ancestor_configs.map(&:variables).reduce(variables, &:reverse_merge) || {}
  end

  def chain_of_ancestor_configs
    @ancestor_configs ||= [self] + (parent && parent.chain_of_ancestor_configs).to_a
  end

  def clone_with_new_parent(new_parent)
    attrs = attributes.with_indifferent_access.slice(*BrandConfig::ATTRS_TO_INCLUDE_IN_MD5)
    attrs[:parent_md5] = if new_parent
                           (new_parent.shard.id == shard.id) ? new_parent.md5 : "#{new_parent.shard.id}~#{new_parent.md5}"
                         else
                           nil
                         end
    BrandConfig.for(attrs)
  end

  def dup?
    BrandConfig.where(md5:).exists?
  end

  def save_unless_dup!
    save! unless dup?
  end

  def to_json(*args)
    BrandableCSS.all_brand_variable_values(self).to_json(*args)
  end

  def to_js
    BrandableCSS.all_brand_variable_values_as_js(self)
  end

  def to_css
    BrandableCSS.all_brand_variable_values_as_css(self)
  end

  def public_brand_dir
    BrandableCSS.public_brandable_css_folder.join(md5)
  end

  def public_folder
    "dist/brandable_css/#{md5}"
  end

  %i[json js css].each do |type|
    define_method :"public_#{type}_path" do
      "#{public_folder}/variables-#{BrandableCSS.default_variables_md5}.#{type}"
    end

    define_method :"#{type}_file" do
      public_brand_dir.join("variables-#{BrandableCSS.default_variables_md5}.#{type}")
    end

    define_method :"save_#{type}_file!" do
      file = send(:"#{type}_file")
      logger.info "saving brand variables #{type} file: #{file}"
      public_brand_dir.mkpath
      file.write(send(:"to_#{type}"))
      send :"move_#{type}_to_s3_if_enabled!"
    end

    define_method :"move_#{type}_to_s3_if_enabled!" do
      return unless Canvas::Cdn.enabled?

      s3_uploader.upload_file(send(:"public_#{type}_path"))
      begin
        File.delete(send(:"#{type}_file"))
      rescue Errno::ENOENT
        # continue if something else deleted it in another process
      end
    end
  end

  def s3_uploader
    @s3_uploaderer ||= Canvas::Cdn::S3Uploader.new
  end

  def save_all_files!
    save_json_file!
    save_js_file!
    save_css_file!
  end

  def css_and_js_overrides
    shard.activate do
      @css_and_js_overrides ||= Rails.cache.fetch([self, "css_and_js_overrides"].cache_key) do
        chain_of_ancestor_configs.each_with_object({}) do |brand_config, includes|
          BrandConfig::OVERRIDE_TYPES.each do |override_type|
            if brand_config[override_type].present?

              (includes[override_type] ||= []).unshift(brand_config[override_type])
            end
          end
        end
      end
    end
  end

  def sync_to_s3_and_save_to_account!(progress, account_or_id)
    save_and_sync_to_s3!(progress)
    account = account_or_id.is_a?(Account) ? account_or_id : Account.find(account_or_id)
    old_md5 = account.brand_config_md5
    account.brand_config_md5 = md5
    account.save!
    BrandConfig.destroy_if_unused(old_md5)
    progress&.increment_completion!(1)
  end

  def sync_to_s3_and_save_to_shared_brand_config!(progress, shared_brand_config_or_id)
    save_and_sync_to_s3!(progress)
    shared_brand_config = if shared_brand_config_or_id.is_a?(SharedBrandConfig)
                            shared_brand_config_or_id
                          else
                            SharedBrandConfig.find(shared_brand_config_or_id)
                          end
    old_md5 = shared_brand_config.brand_config_md5
    shared_brand_config.brand_config_md5 = md5
    shared_brand_config.save!
    BrandConfig.destroy_if_unused(old_md5)
    progress&.increment_completion!(1)
  end

  def save_and_sync_to_s3!(progress = nil)
    save_all_files!
    progress.increment_completion!(4) if progress&.total
  end

  def self.destroy_if_unused(md5)
    return unless md5

    unused_brand_config = BrandConfig
                          .where(md5:)
                          .where.not(Account.where("brand_config_md5=brand_configs.md5").arel.exists)
                          .where.not(SharedBrandConfig.where("brand_config_md5=brand_configs.md5").arel.exists)
                          .first
    unused_brand_config&.destroy
  end

  def self.clean_unused_from_db!
    BrandConfig
      # When someone is actively working in the theme editor, it just saves one
      # in their session, so only delete stuff that is more than a week old,
      # to not clear out a theme someone was working on.
      .where(["created_at < ?", 1.week.ago])
      .where.not(Account.where("brand_config_md5=brand_configs.md5").arel.exists)
      .where.not(SharedBrandConfig.where("brand_config_md5=brand_configs.md5").arel.exists)
      .delete_all
  end
end
