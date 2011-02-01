SanitizeField
=============

We want to be able to mix model fields with Sanitize configuration and
implement a sanitization in a before_save callback.

An alternative to this plugin might be using a Rails whitelist.  This
isn't developed, but is an idea on http://wonko.com/post/sanitize

  Rails::Initializer.run do |config|
    config.action_view.white_list_sanitizer = Sanitizer.new
    config.action_view.sanitized_allowed_tags = ‘table’, ‘tr’, ‘td’
    config.action_view.sanitized_allowed_attributes = ‘id’, ‘class’, ‘style’
  end

Our approach is finer-grained, and should work better for now at least.
There is also talk about an alternative 1.9/nokogiri approach to the
Sanitizer gem for more optimal performance.  Keeping our eyes open
about these issues.

Example
=======

class BasicExample < ActiveRecord::Base
  sanitize :body, Sanitize::Config::RELAXED
end

class Whatever < ActiveRecord::Base
  sanitize :body, :title, :elements => ['a', 'span'],
    :attributes => {'a' => ['href', 'title'], 'span' => ['class']},
    :protocols => {'a' => {'href' => ['http', 'https', 'mailto']}}
end

License
=======

Copyright (C) 2011 Instructure, Inc.

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
