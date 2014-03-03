#
# Copyright (C) 2011 Instructure, Inc.
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

# A couple of notes of discussion from the code review for when this inevitably
# gets used elsewhere:
#  * instance_method will raise an exception if the method doesn't exist; this
#    is _probably_ what you want.
#  * Manipulating after_save_callback_chain etc. may be more performant than
#    redefining methods. That doesn't matter for this use case.  Also, it
#    might not work with Rails 3 (which has built in support for this type
#    of thing), but this way definitely will
class ActiveRecord::Base
  def self.skip_callback(callback, &block)
    method = instance_method(callback)
    begin
      remove_method(callback)
      should_redefine_original_callback = true
    rescue NameError => e
      raise e unless "#{e}" =~ /method `#{Regexp.escape callback.to_s}' not defined in #{Regexp.escape self.name}/
      should_redefine_original_callback = false
    end
    define_method(callback){ true }
    begin
      yield
    ensure
      remove_method(callback)
      define_method(callback, method) if should_redefine_original_callback
    end
  end

  def self.skip_callbacks(*callbacks, &block)
    return block.call if callbacks.size == 0
    skip_callback(callbacks[0]) { skip_callbacks(*callbacks[1..-1], &block) }
  end


  if CANVAS_RAILS2
    def save_without_callbacks
      send new_record? ? :create_without_callbacks : :update_without_callbacks
    end
  else
    def save_without_callbacks
      # adapted from https://github.com/dball/skip_activerecord_callbacks
      class << self
        alias :run_callbacks_orig :run_callbacks
        def run_callbacks(name)
          if name == :update || name == :create
            class << self
              undef :run_callbacks
              alias :run_callbacks :run_callbacks_orig
            end
            yield
          elsif name == :save
            yield
          else
            run_callbacks_orig(name, &Proc.new{})
          end
        end
      end
      save
    end
  end
end
