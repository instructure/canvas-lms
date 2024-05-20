# frozen_string_literal: true

#
# Copyright (C) 2020 - present Instructure, Inc.
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

#
# To use factories in a development rails console, run
#   require 'spec/factories'
#   include Factories
#

module Factories
  def factory_with_protected_attributes(ar_klass, attrs, do_save = true)
    obj = ar_klass.respond_to?(:new) ? ar_klass.new : ar_klass.build
    attrs.each { |k, v| obj.send(:"#{k}=", v) }
    obj.save! if do_save
    obj
  end

  def update_with_protected_attributes!(ar_instance, attrs)
    attrs.each { |k, v| ar_instance.send(:"#{k}=", v) }
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
      next if return_type == :nil

      scope = klass.order("id DESC").limit(records.size)
      if return_type == :record
        scope.to_a.reverse
      else
        scope.pluck(:id).reverse
      end
    end
  end
end

legit_global_methods = Object.private_methods
Dir[File.dirname(__FILE__) + "/factories/**/*.rb"].each { |f| require f }
crap_factories = (Object.private_methods - legit_global_methods)
if crap_factories.present?
  warn "\e[31mError: Don't create global factories/helpers"
  warn "Put #{crap_factories.map { |m| "`#{m}`" }.to_sentence} in the `Factories` module"
  warn "(or somewhere else appropriate)\e[0m"
  $stderr.puts
  exit! 1
end
