#
# Copyright (C) 2014 Instructure, Inc.
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

module ContentNotices
  NOTICE_ATTRIBUTES = [:tag, :text, :template, :alert_class, :icon_class, :should_show]

  class ContentNotice
    attr_accessor *NOTICE_ATTRIBUTES
  end

  module ClassMethods
    #  opts must include exactly one of:
    #    text: string (or Proc that returns string) containing text for the notice
    #    template: erb partial containing html content for the notice
    #  opts may optionally contain:
    #    alert_class: CSS class(es) for the notice box (suggestions: 'alert-info', 'alert-success', 'alert-error')
    #    icon_class: CSS class(es) for the icon (suggestions: 'icon-info', 'icon-check', 'icon-warning')
    #    should_show: callback that receives the context and user, and returns whether the notice should be displayed
    # see course.rb for example usage
    def define_content_notice(tag, opts)
      notice = ContentNotice.new
      NOTICE_ATTRIBUTES.each do |attr|
        notice.instance_variable_set "@#{attr}", opts[attr] if opts.include?(attr)
      end
      notice.tag ||= tag
      @content_notices ||= {}
      @content_notices[tag] = notice
    end

    def content_notices
      @content_notices
    end
  end

  def self.included(base)
    base.extend(ClassMethods)
  end

  def cn_cache_key(tag)
    ["content_notice_present", tag, self.asset_string].cache_key
  end

  # add a notice to this context. if the notice with the given tag is already active for the context,
  # its expiration time will be reset.
  def add_content_notice(tag, expires_in = nil)
    Rails.cache.write(cn_cache_key(tag), true, expires_in: expires_in)
  end

  # remove a notice from this context
  def remove_content_notice(tag)
    Rails.cache.delete(cn_cache_key(tag))
  end

  # return an array of content notices that should be shown to the user
  def content_notices(user)
    self.class.content_notices.select do |tag, notice|
      Rails.cache.read(cn_cache_key(tag)) && (notice.should_show.nil? || notice.should_show.call(self, user))
    end.values
  end

end
