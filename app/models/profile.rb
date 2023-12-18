# frozen_string_literal: true

#
# Copyright (C) 2013 - present Instructure, Inc.
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

class Profile < ActiveRecord::Base
  belongs_to :context, polymorphic: [:course], exhaustive: false
  belongs_to :root_account, class_name: "Account"

  serialize :data

  validates :root_account, presence: true
  validates :context, presence: true
  validates :title, length: { within: 0..255 }
  validates :path, length: { within: 0..255 }
  validates :path, format: { with: /\A[a-z0-9-]+\z/ }
  validates :path, uniqueness: { scope: :root_account_id }
  validates :context_id, uniqueness: { scope: :context_type }
  validates :visibility, inclusion: { in: %w[public unlisted private] }

  def title=(title)
    write_attribute(:title, title)
    write_attribute(:path, infer_path) if path.nil?
  end

  def infer_path
    return nil unless title

    path = base_path = title.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    count = 0
    while (profile = Profile.where(root_account_id:, path:).first)
      break if profile.id == id

      path = "#{base_path}-#{count += 1}"
    end
    path
  end

  def data
    read_or_initialize_attribute(:data, {})
  end

  def data_before_type_cast # for validations and such
    @data_before_type_cast ||= data.dup
  end

  def self.data(field, options = {})
    options[:type] ||= :string
    define_method(field) do
      data.key?(field) ? data[field] : data[field] = options[:default]
    end
    define_method(:"#{field}=") do |value|
      data_before_type_cast[field] = value
      data[field] = sanitize_data(value, options)
    end
    define_method(:"#{field}_before_type_cast") do
      data_before_type_cast[field]
    end
  end

  def sanitize_data(value, options)
    return nil unless value.present?

    case options[:type]
    when :decimal, :float then value.to_f
    when :int then value.to_i
    else value
    end
  end

  # some tricks to make it behave like STI with a type column
  def self.inherited(klass)
    super
    context_type = klass.name.delete_suffix("Profile")
    klass.class_eval { alias_method context_type.downcase.underscore, :context }
  end

  self.inheritance_column = :context_type

  def self.find_sti_class(type_name)
    Object.const_get(:"#{type_name}Profile", false)
  end

  module Association
    def self.prepended(klass)
      klass.has_one :profile, as: :context, inverse_of: :context
    end

    def profile
      super || begin
        profile = Object.const_get(:"#{self.class.name}Profile", false).new(context: self)
        profile.root_account = root_account
        profile.title = name
        profile.visibility = "private"
        profile
      end
    end
  end
end
