#
# Copyright (C) 2014 - present Instructure, Inc.
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
        %r{^/courses/(#{ID})/wiki/([^/?]+)(?:\?[^/]+)?} => ['Page', :api_v1_course_wiki_page_url, :course_id, :url],
        %r{^/groups/(#{ID})/wiki/([^/?]+)(?:\?[^/]+)?} => ['Page', :api_v1_group_wiki_page_url, :group_id, :url],
        %r{^/courses/(#{ID})/pages/([^/?]+)(?:\?[^/]+)?} => ['Page', :api_v1_course_wiki_page_url, :course_id, :url],
        %r{^/groups/(#{ID})/pages/([^/?]+)(?:\?[^/]+)?} => ['Page', :api_v1_group_wiki_page_url, :group_id, :url],

        # List assignments
        %r{^/courses/(#{ID})/assignments$} => ['[Assignment]', :api_v1_course_assignments_url, :course_id],

        # Get assignment
        %r{^/courses/(#{ID})/assignments/(#{ID})$} => ['Assignment', :api_v1_course_assignment_url, :course_id, :id],

        # List files
        %r{^/courses/(#{ID})/files$} => ['Folder', :api_v1_course_folder_url, :course_id, {:id => 'root'}],
        %r{^/groups/(#{ID})/files$} => ['Folder', :api_v1_group_folder_url, :group_id, {:id => 'root'}],
        %r{^/users/(#{ID})/files$} => ['Folder', :api_v1_user_folder_url, :user_id, {:id => 'root'}],

        # Get file
        %r{^/courses/(#{ID})/files/(#{ID})/} => ['File', :api_v1_course_attachment_url, :course_id, :id],
        %r{^/groups/(#{ID})/files/(#{ID})/} => ['File', :api_v1_group_attachment_url, :group_id, :id],
        %r{^/users/(#{ID})/files/(#{ID})/} => ['File', :api_v1_user_attachment_url, :user_id, :id],
        %r{^/files/(#{ID})/} => ['File', :api_v1_attachment_url, :id],

        # List quizzes
        %r{^/courses/(#{ID})/quizzes$} => ['[Quiz]', :api_v1_course_quizzes_url, :course_id],

        # Get quiz
        %r{^/courses/(#{ID})/quizzes/(#{ID})$} => ['Quiz', :api_v1_course_quiz_url, :course_id, :id],

        # List modules
        %r{^/courses/(#{ID})/modules$} => ['[Module]', :api_v1_course_context_modules_url, :course_id],

        # Get module
        %r{^/courses/(#{ID})/modules/(#{ID})$} => ['Module', :api_v1_course_context_module_url, :course_id, :id],

        # Launch LTI tool
        %r{^/courses/(#{ID})/external_tools/retrieve\?url=(.*)$} => ['SessionlessLaunchUrl', :api_v1_course_external_tool_sessionless_launch_url, :course_id, :url],
    }.freeze

    class UrlProxy
      attr_reader :proxy, :context, :host, :protocol, :target_shard
      def initialize(helper, context, host, protocol, target_shard: nil)
        @proxy = helper
        @context = context
        @host = host
        @protocol = protocol
        @target_shard = target_shard || context.shard
      end

      def media_object_thumbnail_url(media_id)
        proxy.media_object_thumbnail_url(media_id, width: 550, height: 448, type: 3, host: host, protocol: protocol)
      end

      def media_context
        case context
        when Group
          context.context
        when CourseSection
          context.course
        else
          context
        end
      end

      def media_redirect_url(media_id, media_type)
        proxy.polymorphic_url([media_context, :media_download], entryId: media_id, media_type: media_type, redirect: '1', host: host, protocol: protocol)
      end

      def show_media_tracks_url(media_object_id, media_id)
        proxy.show_media_tracks_url(media_object_id, media_id, format: :json, host: host, protocol: protocol)
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
              # transpose IDs in the URL
              if context.shard != target_shard && (args = recognize_path(url_str))
                transpose_ids(args)
                args[:host] = host
                args[:protocol] = protocol
                element[attribute] = proxy.url_for(args)
              else
                element[attribute] = "#{protocol}://#{host}#{url_str}"
              end
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
          # transpose IDs in the URL
          transpose_ids(args) if context.shard != target_shard
          if args[:url] && (return_type == 'SessionlessLaunchUrl' || (return_type == "Page" && url.include?("titleize=0")))
            args[:url] = URI.unescape(args[:url])
          end
          api_route.slice(match.captures.size + 2, 1).each { |opts| args.merge!(opts) }
          return { 'data-api-endpoint' => proxy.send(helper, args), 'data-api-returntype' => return_type }
        end
        {}
      end

      # based on ActionDispatch::Routing::RouteSet#recognize_path, but returning all params,
      # not just path_params. and failures return nil, not raise an exception
      def recognize_path(path)
        path = ActionDispatch::Journey::Router::Utils.normalize_path(path)

        begin
          env = Rack::MockRequest.env_for(path, method: "GET")
        rescue URI::InvalidURIError
          return nil
        end

        req = Rails.application.routes.send(:make_request, env)
        Rails.application.routes.router.recognize(req) do |route, params|
          params.each do |key, value|
            if value.is_a?(String)
              value = value.dup.force_encoding(Encoding::BINARY)
              params[key] = URI.parser.unescape(value)
            end
          end
          req.path_parameters = params
          app = route.app
          if app.matches?(req) && app.dispatcher?
            return req.params
          end
        end

        nil
      end

      def transpose_ids(args)
        args.each_key do |key|
          if (key.to_s == 'id' || key.to_s.end_with?('_id')) &&
            (new_id = Switchman::Shard.relative_id_for(args[key], context.shard, target_shard))
            args[key] = Switchman::Shard.short_id_for(new_id)
          end
        end
      end
    end
  end
end
