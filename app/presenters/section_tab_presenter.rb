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

class SectionTabPresenter
  include Rails.application.routes.url_helpers

  def initialize(tab, context)
    @tab = OpenStruct.new(tab)
    @context = context
  end
  attr_reader :tab, :context

  delegate :css_class, :label, :target, to: :tab

  def active?(active_tab)
    active_tab == tab.css_class
  end

  def hide?
    tab.hidden
  end

  def unused?
    tab.hidden_unused
  end

  def target?
    !!(tab.respond_to?(:target) && tab.target)
  end

  def path
    tab.args = tab.args.symbolize_keys if tab.href.to_s == "course_basic_lti_launch_request_path"
    tab.args.instance_of?(Hash) ? send(tab.href, tab.args) : send(tab.href, *path_args)
  end

  def path_args
    tab.args || (tab.no_args && []) || context
  end

  def to_h
    {
      css_class: tab.css_class,
      icon: tab.icon,
      hidden: hide? || unused?,
      path:,
      label: tab.label
    }
  end
end
