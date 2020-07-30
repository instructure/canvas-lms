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
end

legit_global_methods = Object.private_methods
Dir[File.dirname(__FILE__) + "/factories/**/*.rb"].each {|f| require f }
crap_factories = (Object.private_methods - legit_global_methods)
if crap_factories.present?
  $stderr.puts "\e[31mError: Don't create global factories/helpers"
  $stderr.puts "Put #{crap_factories.map { |m| "`#{m}`" }.to_sentence} in the `Factories` module"
  $stderr.puts "(or somewhere else appropriate)\e[0m"
  $stderr.puts
  exit! 1
end
