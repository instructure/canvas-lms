#
# Copyright (C) 2013 Instructure, Inc.
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

require 'timeout'

module IncomingMailProcessor

  # Internal: A helper mixin for Mailbox implementation to properly implement
  # a configurable timeout. This keeps the Mailbox classes from directly
  # depending on canvas methods. The IncomingMessageProcessor will configure
  # the Mailboxes with the appropriate timeout method to use in a Canvas
  # periodic job.
  module ConfigurableTimeout

    # Public: Set the method to call to implement timeouts. By default this
    # mixin will use the stdlib Timeout module.
    #
    # timeout_method - a block to call that implements a timeout. The block
    #                  should take no parameters except the block to yield to.
    #                  The timeout_method should return the return value of the
    #                  block passed in and raise an exception on timeout.
    #
    # Examples
    #
    #   class Foo
    #     include ConfigurableTimeout
    #
    #     def initialize
    #       set_timout_method &method(:custom_timeout_method)
    #     end
    #
    #     def custom_timeout_method
    #       Timeout.timeout(42) do
    #          yield
    #       end
    #     end
    #   end
    #
    # Returns nothing.
    def set_timeout_method(&timeout_method)
      @timeout_method = timeout_method
    end

    # Public: Calls the configured timeout_method with the specified block.
    # Any exceptions thrown by the block are allowed to escape this method.
    #
    # block - The block to pass to the configured timeout method.
    #
    # Returns the return value of the configured timeout method.
    # Raises anything the timeout method raises.
    def with_timeout(&block)
      method = @timeout_method || method(:default_timeout_method)
      method.call &block
    end

    # Public: Wrap an object's methods in with_timeout calls. The original
    # methods will be available with an "untimed_" prefix.
    #
    # obj     - The object whose methods will be wrapped
    # methods - An Array of Symbols of method names to wrap
    #
    # Examples
    #
    #   obj = FooBar.new
    #   wrap_with_timeout(obj, [:foo, :bar])
    #   obj.foo         # could result in a Timeout::Error
    #   obj.untimed_bar # call original bar method without a timeout
    #
    # Returns nothing.
    def wrap_with_timeout(obj, method_names)
      timeouter = self
      obj_eigenclass = class <<obj; self; end
      method_names.each do |method_name|
        renamed_method_name = "untimed_#{method_name}"
        obj_eigenclass.send(:alias_method, renamed_method_name, method_name)
        obj_eigenclass.send(:define_method, method_name) do |*args, &blk|
          timeouter.with_timeout { send(renamed_method_name, *args, &blk) }
        end
      end
    end

    # Internal: The default timeout method, which uses the stdlib Timeout
    # module.
    #
    # Returns the return value of the block.
    # Raises Timeout::Error if the block takes longer than the default timeout
    #   duration.
    def default_timeout_method()
      Timeout.timeout(default_timeout_duration) do
        yield
      end
    end

    # Internal: The default timeout duration for default_timeout_method. The
    # default timeout is 15 seconds.
    #
    # Returns the default timeout duration Integer.
    def default_timeout_duration
      15
    end
  end
end
