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

module Api
  module Html
    # maps canvas URLs to API URL helpers
    # target array is return type, helper, name of each capture, and optionally a Hash of extra arguments
    API_ROUTE_MAP = {
        # list discussion topics
        %r{^/courses/(#{ID})/discussion_topics$} => ['[Discussion]', :api_v1_course_discussion_topics_url, :course_id],
        %r{^/groups/(#{ID})/discussion_topics$} => ['[Discussion]', :api_v1_group_discussion_topics_url, :group_id],

        # get a single topic
        %r{^/courses/(#{ID})/discussion_topics/(#{ID})$} => ['Discussion', :api_v1_course_discussion_topic_url, :course_id, :topic_id],
        %r{^/groups/(#{ID})/discussion_topics/(#{ID})$} => ['Discussion', :api_v1_group_discussion_topic_url, :group_id, :topic_id],

        # List pages
        %r{^/courses/(#{ID})/wiki$} => ['[Page]', :api_v1_course_wiki_pages_url, :course_id],
        %r{^/groups/(#{ID})/wiki$} => ['[Page]', :api_v1_group_wiki_pages_url, :group_id],
        %r{^/courses/(#{ID})/pages$} => ['[Page]', :api_v1_course_wiki_pages_url, :course_id],
        %r{^/groups/(#{ID})/pages$} => ['[Page]', :api_v1_group_wiki_pages_url, :group_id],

        # Show page
        %r{^/courses/(#{ID})/wiki/([^/]+)$} => ['Page', :api_v1_course_wiki_page_url, :course_id, :url],
        %r{^/groups/(#{ID})/wiki/([^/]+)$} => ['Page', :api_v1_group_wiki_page_url, :group_id, :url],
        %r{^/courses/(#{ID})/pages/([^/]+)$} => ['Page', :api_v1_course_wiki_page_url, :course_id, :url],
        %r{^/groups/(#{ID})/pages/([^/]+)$} => ['Page', :api_v1_group_wiki_page_url, :group_id, :url],

        # List assignments
        %r{^/courses/(#{ID})/assignments$} => ['[Assignment]', :api_v1_course_assignments_url, :course_id],

        # Get assignment
        %r{^/courses/(#{ID})/assignments/(#{ID})$} => ['Assignment', :api_v1_course_assignment_url, :course_id, :id],

        # List files
        %r{^/courses/(#{ID})/files$} => ['Folder', :api_v1_course_folder_url, :course_id, {:id => 'root'}],
        %r{^/groups/(#{ID})/files$} => ['Folder', :api_v1_group_folder_url, :group_id, {:id => 'root'}],
        %r{^/users/(#{ID})/files$} => ['Folder', :api_v1_user_folder_url, :user_id, {:id => 'root'}],

        # Get file
        %r{^/courses/#{ID}/files/(#{ID})/} => ['File', :api_v1_attachment_url, :id],
        %r{^/groups/#{ID}/files/(#{ID})/} => ['File', :api_v1_attachment_url, :id],
        %r{^/users/#{ID}/files/(#{ID})/} => ['File', :api_v1_attachment_url, :id],
        %r{^/files/(#{ID})/} => ['File', :api_v1_attachment_url, :id],

        # List quizzes
        %r{^/courses/(#{ID})/quizzes$} => ['[Quiz]', :api_v1_course_quizzes_url, :course_id],

        # Get quiz
        %r{^/courses/(#{ID})/quizzes/(#{ID})$} => ['Quiz', :api_v1_course_quiz_url, :course_id, :id],

        # Launch LTI tool
        %r{^/courses/(#{ID})/external_tools/retrieve\?url=(.*)$} => ['SessionlessLaunchUrl', :api_v1_course_external_tool_sessionless_launch_url, :course_id, :url],
    }.freeze

    class UrlProxy
      attr_reader :proxy, :context, :host, :protocol
      def initialize(helper, context, host, protocol)
        @proxy = helper
        @context = context
        @host = host
        @protocol = protocol
      end

      def media_object_thumbnail_url(media_id)
        proxy.media_object_thumbnail_url(media_id, width: 550, height: 448, type: 3, host: host, protocol: protocol)
      end

      def media_redirect_url(media_id, media_type)
        proxy.polymorphic_url([context, :media_download], entryId: media_id, media_type: media_type, redirect: '1', host: host, protocol: protocol)
      end

      # rewrite any html attributes that are urls but just absolute paths, to
      # have the canvas domain prepended to make them a full url
      #
      # relative urls and invalid urls are currently ignored
      def rewrite_api_urls(element, attributes)
        attributes.each do |attribute|
          url_str = element[attribute]
          begin
            url = URI.parse(url_str)
            # if the url_str is "//example.com/a", the parsed url will have a host set
            # otherwise if it starts with a slash, it's a path that needs to be
            # made absolute with the canvas hostname prepended
            if !url.host && url_str[0] == '/'[0]
              element[attribute] = "#{protocol}://#{host}#{url_str}"
              api_endpoint_info(url_str).each do |att, val|
                element[att] = val
              end
            end
          rescue URI::Error => e
            # leave it as is
          end
        end
      end

      def api_endpoint_info(url)
        API_ROUTE_MAP.each_pair do |re, api_route|
          match = re.match(url)
          next unless match
          return_type = api_route[0]
          helper = api_route[1]
          args = { :protocol => protocol, :host => host }
          args.merge! Hash[api_route.slice(2, match.captures.size).zip match.captures]
          api_route.slice(match.captures.size + 2, 1).each { |opts| args.merge!(opts) }
          return { 'data-api-endpoint' => proxy.send(helper, args), 'data-api-returntype' => return_type }
        end
        {}
      end
    end
  end
end
