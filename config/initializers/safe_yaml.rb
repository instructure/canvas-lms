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
#

ADDITIONAL_ALLOWED_CLASSES = [
  ActiveSupport::HashWithIndifferentAccess,
  ActiveSupport::SafeBuffer,
  ActiveSupport::TimeWithZone,
  ActiveSupport::TimeZone,
  ActionController::Parameters,
  BigDecimal,
  Date,
  DateTime,
  Mime::Type,
  Mime::NullType,
  OpenObject,
  OpenStruct,
  Symbol,
  Time,
  URI::HTTP,
  URI::HTTPS
].freeze

# SafeYAML-like interface, but vanilla Psych
module SafeYAML
  class << self
    attr_accessor :permitted_classes

    def whitelist_class!(*klasses)
      permitted_classes.concat(klasses).uniq!
    end
  end

  self.permitted_classes = []
  whitelist_class!(*ADDITIONAL_ALLOWED_CLASSES)

  module Psych
    if ::Psych::VERSION < "4"
      # load defaults to safe
      def load(*args, safe: true, **kwargs)
        return super(*args, **kwargs) unless safe

        safe_load(*args, **kwargs)
      end

      def unsafe_load(*args, **kwargs)
        load(*args, safe: false, **kwargs)
      end
    else
      def load(*args, safe: true, **kwargs)
        return unsafe_load(*args, **kwargs) unless safe

        super(*args, aliases: true, **kwargs)
      end
    end

    def safe_load(yaml, permitted_classes: [], **kwargs)
      super(yaml, permitted_classes: permitted_classes + SafeYAML.permitted_classes, aliases: true, **kwargs)
    end
  end
end
Psych.singleton_class.prepend(SafeYAML::Psych)

ActiveRecord.yaml_column_permitted_classes = ADDITIONAL_ALLOWED_CLASSES

module ScalarScannerFix
  # in rubies < 2.7, Psych uses a regex to identify an integer, then strips commas and underscores,
  # then checks _again_ against the regex. In 2.7, the second check was eliminated because the
  # stripping was inlined in the name of optimization to avoid a string allocation. unfortunately
  # this means something like 0x_ which passes the first check is not a valid number, and will
  # throw an exception. this is the simplest way to catch that case without completely reverting
  # the optimization
  def parse_int(string)
    super
  rescue ArgumentError
    string
  end
end
Psych::ScalarScanner.prepend(ScalarScannerFix)

module YAMLSingletonFix
  def revive(klass, node)
    if klass < Singleton
      klass.instance
    elsif klass == Set
      super.tap { |s| s.instance_variable_get(:@hash).default = false }
    else
      super
    end
  end
end
Psych::Visitors::ToRuby.prepend(YAMLSingletonFix)
