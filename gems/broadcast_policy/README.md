BroadcastPolicy
===============

This allows us to do something like:

class Model < ActiveRecord::Base
  has_a_broadcast_policy

  set_broadcast_policy do |p|
    p.dispatch :notification_name
    p.to { some_endpoints }
    p.whenever { |record|
      record.foo_is_true? && record.bar_is_false?
    }
  end

end
  
## Usage

In order to use the gem in Rails, you'll need an initializer something like this:

config/initializers/broadcast_policy.rb

require 'broadcast_policy'
BroadcastPolicy.notifier = lambda { Notifier.new }
BroadcastPolicy.notification_finder = lambda { NotificationFinder.new(Nofication.all) }
ActiveRecord::Base.send(:extend, BroadcastPolicy::ClassMethods)

The two BroadcastPolicy services are necessary to supply the canvas domain objects
for integrating with the notification system
License
=======

Copyright (C) 2014 Instructure, Inc.

This file is part of Canvas.

Canvas is free software: you can redistribute it and/or modify it under
the terms of the GNU Affero General Public License as published by the Free
Software Foundation, version 3 of the License.

Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
details.

You should have received a copy of the GNU Affero General Public License along
with this program. If not, see <http://www.gnu.org/licenses/>.
