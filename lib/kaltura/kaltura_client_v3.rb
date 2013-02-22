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

require 'rubygems'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'libxml'

# Test Console and API Documentation at:
# http://www.kaltura.com/api_v3/testmeDoc/index.php
module Kaltura
  include Multipart
  class SessionType
    USER = 0;
    ADMIN = 2;
  end

  class ClientV3
    attr_accessor :endpoint, :ks

    def initialize
      config = Kaltura::ClientV3.config
      @host = config['domain']
      @resource_domain = config['resource_domain']
      @endpoint = config['endpoint']
      @partnerId = config['partner_id']
      @secret = config['secret_key']
      @user_secret = config['user_secret_key']
      @host ||= "www.kaltura.com"
      @endpoint ||= "/api_v3"
      if @cache_play_list_seconds = config['cache_play_list_seconds']
        @cache_play_list_seconds = @cache_play_list_seconds.to_i
      end
    end

    def self.config
      res = Canvas::Plugin.find(:kaltura).try(:settings)
      return nil unless res && res['partner_id'] && res['subpartner_id']

      # default settings
      res['max_file_size_bytes'] = 500.megabytes unless res['max_file_size_bytes'].to_i > 0

      res
    end

    CONTENT_TYPES = {
      'mp4' => 'video/mp4',
      'mp3' => 'audio/mp3',
      'flv' => 'video/x-flv'
    }
    # FLVs are least desirable because the mediaelementjs does not stretch them to
    # fill the screen when you enter fullscreen mode
    PREFERENCE = ['mp4', 'mp3', 'flv', '']

    # see http://www.kaltura.com/api_v3/testmeDoc/index.php?object=KalturaFlavorAssetStatus
    ASSET_STATUSES = {
      '1' => :CONVERTING,
      '3' => :DELETED,
      '-1' => :ERROR,
      '9' => :EXPORTING,
      '7' => :IMPORTING,
      '4' => :NOT_APPLICABLE,
      '0' => :QUEUED,
      '2' => :READY,
      '5' => :TEMP,
      '8' => :VALIDATING,
      '6' => :WAIT_FOR_CONVERT
    }

    def media_sources(entryId)
      cache_key = ['media_sources', entryId, @cache_play_list_seconds].cache_key
      sources = Rails.cache.read(cache_key)
      unless sources
        startSession(Kaltura::SessionType::ADMIN)
        assets = flavorAssetGetByEntryId(entryId)
        sources = []
        all_assets_are_done_converting = true
        assets.each do |asset|
          if ASSET_STATUSES[asset[:status]] == :READY
            hash = asset.slice :containerFormat, :width, :fileExt, :size, :bitrate, :height, :isOriginal
            hash[:url] = flavorAssetGetPlaylistUrl(entryId, asset[:id])

            if hash[:url].blank?
              Rails.logger.warn "kaltura entry (#{entryId}) has asset (#{asset[:id]}) with a missing url"
              next
            end

            hash[:content_type] = CONTENT_TYPES[asset[:fileExt]]
            sources << hash
          else
            # if it was deleted or if it did not convert because it did not need to
            # (e.g, a high quality flavor for a file low quality original, like a webcam recording),
            # don't mark it as needing conversion.
            all_assets_are_done_converting = false unless [:NOT_APPLICABLE, :DELETED].include? ASSET_STATUSES[asset[:status]]
          end

        end
        sources = sort_source_list(sources)
        # only cache if all the sources are done converting
        # @cache_play_list_seconds of 0 means don't cache
        # @cache_play_list_seconds of nil means cache indefinitely
        if @cache_play_list_seconds != 0 && sources.present? && all_assets_are_done_converting
          if @cache_play_list_seconds
            Rails.cache.write(cache_key, sources, :expires_in => @cache_play_list_seconds)
          else
            Rails.cache.write(cache_key, sources)
          end
        end
      end
      sources
    end

    # Given an array of sources, it will sort them putting preferred file types at the front,
    # and sorting by descending bitrate for identical file types.
    def sort_source_list(sources)
      sources.sort_by do |a|
        [PREFERENCE.index(a[:fileExt]) || PREFERENCE.size + 1, 0 - a[:bitrate].to_i]
      end
    end

    def thumbnail_url(entryId, opts = {})
      opts = {
        :width => 140,
        :height => 100,
        :vid_sec => 5,
        :bgcolor => "ffffff",
        :type => "2",
        :protocol => ""
      }.merge(opts)

      protocol = if [ "http", "https" ].include?(opts[:protocol])
        opts[:protocol] + ":"
      else
        ""
      end

      "#{protocol}" +
        "//#{@resource_domain}/p/#{@partnerId}/thumbnail" +
        "/entry_id/#{entryId.gsub(/[^a-zA-Z0-9_]/, '')}" +
        "/width/#{opts[:width].to_i}" +
        "/height/#{opts[:height].to_i}" +
        "/bgcolor/#{opts[:bgcolor].gsub(/[^a-fA-F0-9]/, '')}" +
        "/type/#{opts[:type].to_i}" +
        "/vid_sec/#{opts[:vid_sec].to_i}"
    end

    def startSession(type = SessionType::USER, userId = nil)
      partnerId = @partnerId
      secret = type == SessionType::USER ? @user_secret : @secret
      result = sendRequest(:session, :start,
                           :secret => secret,
                           :partnerId => partnerId,
                           :userId => userId,
                           :type => type)
      @ks = result.content
    end

    def mediaGet(entryId)
      result = sendRequest(:media, :get,
                            :ks => @ks,
                            :entryId => entryId)
      item = {}
      result.children.each do |child|
        item[child.name.to_sym] = child.content
      end
      item
    end

    def mediaUpdate(entryId, attributes)
      hash = {
        :ks => @ks,
        :entryId => entryId
      }
      attributes.each do |key, val|
        hash["mediaEntry:#{key}"] = val
      end
      result = sendRequest(:media, :update, hash)
      item = {}
      result.children.each do |child|
        item[child.name.to_sym] = child.content
      end
      item
    end

    def mediaDelete(entryId)
      hash = {
        :ks => @ks,
        :entryId => entryId
      }
      result = sendRequest(:media, :delete, hash)
      result
    end

    def mediaTypeToSymbol(type)
      case type.to_i
      when 1
        :video
      when 2
        :image
      when 5
        :audio
      else
        :video
      end
    end

    def bulkUploadGet(id)
      result = sendRequest(:bulkUpload, :get,
                           :ks => @ks,
                           :id => id
                          )
      parseBulkUpload(result)
    end

    def parseBulkUpload(result)
      data = {}
      data[:result] = result
      url = result.css('logFileUrl')[0].content
      csv = FasterCSV.parse(Canvas::HTTP.get(url).body)
      data[:entries] = []
      csv.each do |row|
        data[:entries] << {
          :name => row[0],
          :entryId => row[-3],
          :originalId => row[11]
        }
      end
      data[:id] = result.css('id')[0].content
      data[:status] = result.css('status')[0].content
      data[:ready] = !csv.empty? && csv[0][0] != "Log file is not ready"
      data
    end

    def bulkUploadCsv(csv)
      result = postRequest(:bulkUpload, :add,
                           :ks => @ks,
                           :conversionProfileId => -1,
                           :csvFileData => KalturaStringIO.new(csv, "bulk_data.csv")
                       )
      parseBulkUpload(result)
      # results will have entryId values -- do we get them right away?
    end

    def bulkUploadAdd(files)
      rows = []
      files.each do |file|
        filename = (file[:name] || "Media File").gsub(/,/, "")
        description = (file[:description] || "no description").gsub(/,/, "")
        url = file[:url]
        rows << [filename, description, file[:tags] || "", url, file[:media_type] || "video", '', '', '' ,'' ,'' ,'' ,file[:id] || ''] if file[:url]
      end
      res = FasterCSV.generate do |csv|
        rows.each do |row|
          csv << row
        end
      end
      bulkUploadCsv(res)
    end

    def flavorAssetGetByEntryId(entryId)
      result = sendRequest(:flavorAsset, :getByEntryId,
                           :ks => @ks,
                           :entryId => entryId)
      items = []
      result.css('item').each do |node|
        item = {}
        node.children.each do |child|
          item[child.name.to_sym] = child.content
        end
        items << item
      end
      items
    end

    # returns the original flavor of the asset, or the first flavor if for some
    # reason the original can't be found.
    def flavorAssetGetOriginalAsset(entryId)
      flavors = flavorAssetGetByEntryId(entryId)
      flavors.find { |f| f[:isOriginal] == 1 } || flavors.first
    end

    def flavorAssetGetDownloadUrl(assetId)
      result = sendRequest(:flavorAsset, :getDownloadUrl,
                           :ks => @ks,
                           :id => assetId)
      return result.content
    end

    # This is not a true Kaltura API call, but generates the url for a "playlist"
    # and gets the desired URL from there. These URLs point to any CDN configured
    # in Kaltura and thus are preferable to using flavorAssetGetDownloadUrl which
    # will likely download from Kaltura, and not S3 (for example).
    def flavorAssetGetPlaylistUrl(entryId, flavorId)
      playlist_url = "/p/#{@partnerId}/playManifest/entryId/#{entryId}/flavorId/#{flavorId}"
      res = Net::HTTP.get_response(@host, playlist_url)
      return nil unless res.kind_of?(Net::HTTPSuccess)

      doc = Nokogiri::XML(res.body)
      mediaNode = doc.css('manifest media').first
      mediaNode ? mediaNode["url"] : nil
    end

    def assetSwfUrl(assetId, protocol = "http")
      config = Kaltura::ClientV3.config
      return nil unless config
      "#{protocol}://#{config['domain']}/kwidget/wid/_#{config['partner_id']}/uiconf_id/#{config['player_ui_conf']}/entry_id/#{assetId}"
    end

    private

    def postRequest(service, action, params)
      mp = Multipart::MultipartPost.new
      query, headers = mp.prepare_query(params)
      res = nil
      Net::HTTP.start(@host) {|con|
        req = Net::HTTP::Post.new(@endpoint + "/?service=#{service}&action=#{action}", headers)
        con.read_timeout = 30
        begin
          res = con.request(req, query) #con.post(url.path, query, headers)
        rescue => e
          puts "POSTING Failed #{e}... #{Time.now}"
        end
      }
      doc = Nokogiri::XML(res.body)
      doc.css('result').first
    end
    def sendRequest(service, action, params)
      requestParams = "service=#{service}&action=#{action}"
      params.each do |key, value|
        next if value.nil?
        requestParams += "&#{URI.escape(key.to_s)}=#{URI.escape(value.to_s)}"
      end
      res = Net::HTTP.get_response(@host, "#{@endpoint}/?#{requestParams}")
      doc = Nokogiri::XML(res.body)
      doc.css('result').first
    end
  end
end

