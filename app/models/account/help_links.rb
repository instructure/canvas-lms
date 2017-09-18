#
# Copyright (C) 2016 - present Instructure, Inc.
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

class Account::HelpLinks
  class << self
    def default_links
      [
        {
          :available_to => ['student'],
          :text => -> { I18n.t('#help_dialog.instructor_question', 'Ask Your Instructor a Question') },
          :subtext => -> { I18n.t('#help_dialog.instructor_question_sub', 'Questions are submitted to your instructor') },
          :url => '#teacher_feedback',
          :type => 'default',
          :id => :instructor_question
        }.freeze,
        {
          :available_to => ['user', 'student', 'teacher', 'admin'],
          :text => -> { I18n.t('#help_dialog.search_the_canvas_guides', 'Search the Canvas Guides') },
          :subtext => -> { I18n.t('#help_dialog.canvas_help_sub', 'Find answers to common questions') },
          :url => Setting.get('help_dialog_canvas_guide_url', 'http://community.canvaslms.com/community/answers/guides'),
          :type => 'default',
          :id => :search_the_canvas_guides
        }.freeze,
        {
          :available_to => ['user', 'student', 'teacher', 'admin'],
          :text => -> { I18n.t('#help_dialog.report_problem', 'Report a Problem') },
          :subtext => -> { I18n.t('#help_dialog.report_problem_sub', 'If Canvas misbehaves, tell us about it') },
          :url => '#create_ticket',
          :type => 'default',
          :id => :report_a_problem
        }.freeze
      ]
    end

    def default_links_hash
      @default_links_hash ||= default_links.index_by { |link| link[:id] }
    end

    def instantiate_links(links)
      links.map do |link|
        link = link.dup
        link[:text] = link[:text].call if link[:text].respond_to?(:call)
        link[:subtext] = link[:subtext].call if link[:subtext].respond_to?(:call)
        link
      end
    end

    # take an array of links, and replace the duplicated default links with
    # the canonical version from the code. This makes sure the text translates,
    # and that updates to the link are pushed through. available_to is not copied,
    # so that a school can still customize it
    def map_default_links(links)
      links.map do |link|
        default_link = link[:type] == 'default' && default_links_hash[link[:id]&.to_sym]
        if default_link
          link = link.dup
          link[:text] = default_link[:text]
          link[:subtext] = default_link[:subtext]
          link[:url] = default_link[:url]
        end
        link
      end
    end
  end
end
