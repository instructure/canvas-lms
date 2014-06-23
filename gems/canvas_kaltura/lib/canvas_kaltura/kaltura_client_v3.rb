#
# Copyright (C) 2011 - 2014 Instructure, Inc.
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
require 'csv'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'libxml'
require 'multipart'


# Test Console and API Documentation at:
# http://www.kaltura.com/api_v3/testmeDoc/index.php
module CanvasKaltura

  class SessionType
    USER = 0;
    ADMIN = 2;
  end

  class ClientV3
    attr_accessor :endpoint, :ks

    def initialize
      config = CanvasKaltura::ClientV3.config
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
      @kaltura_sis = config['kaltura_sis']
    end

    def self.config
      res = CanvasKaltura.plugin_settings.try(:settings)
      return nil unless res && res['partner_id'] && res['subpartner_id']

      # default settings
      res = res.dup
      # the kaltura flash widget's calculation is a bit off, so give a bit extra space
      # to make sure 500 mb files can be uploaded
      res['max_file_size_bytes'] = 510.megabytes unless res['max_file_size_bytes'].to_i > 0

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
      cache_key = ['media_sources2', entryId, @cache_play_list_seconds].join('/')
      sources = CanvasKaltura.cache.read(cache_key)

      unless sources
        startSession(CanvasKaltura::SessionType::ADMIN)
        assets = flavorAssetGetByEntryId(entryId)
        sources = []
        all_assets_are_done_converting = true
        assets.each do |asset|
          if ASSET_STATUSES[asset[:status]] == :READY
            keys = [:containerFormat, :width, :fileExt, :size, :bitrate, :height, :isOriginal]
            hash = asset.select{|k| keys.member?(k)}

            hash[:url] = flavorAssetGetPlaylistUrl(entryId, asset[:id])
            if hash[:content_type] = CONTENT_TYPES[asset[:fileExt]]
              hash[:url] ||= flavorAssetGetDownloadUrl(asset[:id])
            end

            if hash[:url].nil? || hash[:url].strip.empty? || hash[:content_type].nil? || hash[:content_type].strip.empty?
              CanvasKaltura.logger.warn "kaltura entry (#{entryId}) has an invalid asset (#{asset[:id]})"
              next
            end

            hash[:hasWarnings] = true if asset[:description] && asset[:description].include?("warnings")

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
        if @cache_play_list_seconds != 0 && !sources.empty? && all_assets_are_done_converting
          if @cache_play_list_seconds
            CanvasKaltura.cache.write(cache_key, sources, :expires_in => @cache_play_list_seconds)
          else
            CanvasKaltura.cache.write(cache_key, sources)
          end
        end
      end
      sources
    end

    # Given an array of sources, it will sort them putting preferred file types at the front,
    # preferring converted assets over the original (since they're likely to stream better)
    # and sorting by descending bitrate for identical file types, discounting
    # suspiciously high bitrates.
    def sort_source_list(sources)
      original_source = sources.detect{ |s| s[:isOriginal].to_i != 0 }
      # CNVS-11227 features broken conversions at 20x+ the original source's bitrate
      # (in addition to working conversions at bitrates comparable to the original)
      suspicious_bitrate_threshold = original_source ? original_source[:bitrate].to_i * 5 : 0

      sources = sources.sort_by do |a|
        [a[:hasWarnings] || a[:isOriginal] != '0' ? CanvasSort::Last : CanvasSort::First,
         a[:isOriginal] == '0' ? CanvasSort::First : CanvasSort::Last,
         PREFERENCE.index(a[:fileExt]) || PREFERENCE.size + 1,
         a[:bitrate].to_i < suspicious_bitrate_threshold ? CanvasSort::First : CanvasSort::Last,
         0 - a[:bitrate].to_i]
      end

      sources.each{|a| a.delete(:hasWarnings)}
      sources
    end

    def thumbnail_url(entryId, opts = {})
      opts = {
        :width => 140,
        :height => 100,
        :vid_sec => 5,
        :bgcolor => "ffffff",
        :type => "2",
      }.merge(opts)

        "https://#{@resource_domain}/p/#{@partnerId}/thumbnail" +
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
      result = getRequest(:session, :start,
                           :secret => secret,
                           :partnerId => partnerId,
                           :userId => userId,
                           :type => type)
      @ks = result.content
    end

    def mediaGet(entryId)
      result = getRequest(:media, :get,
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
      result = getRequest(:media, :update, hash)
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
      getRequest(:media, :delete, hash)
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
      result = getRequest(:bulkUpload, :get,
                           :ks => @ks,
                           :id => id
                          )
      parseBulkUpload(result)
    end

    def parseBulkUpload(result)
      data = {}
      data[:result] = result
      url = result.css('logFileUrl')[0].content
      csv = CSV.parse(CanvasHttp.get(url).body)
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
      unless result.css('logFileUrl').any?
        code = result.css('error > code').first.try(:content)
        message = result.css('error > message').first.try(:content)
        message ||= result.to_xml
        raise "kaltura bulkUpload failed: #{message} (#{code})"
      end
      parseBulkUpload(result)
      # results will have entryId values -- do we get them right away?
    end

    def bulkUploadAdd(files)
      rows = []
      files.each do |file|
        filename = (file[:name] || "Media File").gsub(/,/, "")
        description = (file[:description] || "no description").gsub(/,/, "")
        url = file[:url]
        rows << [filename, description, file[:tags] || "", url, file[:media_type] || "video", '', '', '' ,'' ,'' ,'' ,file[:partner_data] || ''] if file[:url]
      end
      res = CSV.generate do |csv|
        rows.each do |row|
          csv << row
        end
      end
      bulkUploadCsv(res)
    end

    def flavorAssetGetByEntryId(entryId)
      result = getRequest(:flavorAsset, :getByEntryId,
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
      result = getRequest(:flavorAsset, :getDownloadUrl,
                           :ks => @ks,
                           :id => assetId)
      return result.content if result
    end

    # This is not a true Kaltura API call, but generates the url for a "playlist"
    # and gets the desired URL from there. These URLs point to any CDN configured
    # in Kaltura and thus are preferable to using flavorAssetGetDownloadUrl which
    # will likely download from Kaltura, and not S3 (for example).
    def flavorAssetGetPlaylistUrl(entryId, flavorId)
      playlist_url = "/p/#{@partnerId}/playManifest/entryId/#{entryId}/flavorId/#{flavorId}"

      res = sendRequest(Net::HTTP::Get.new(playlist_url))
      return nil unless res.kind_of?(Net::HTTPSuccess)

      doc = Nokogiri::XML(res.body)
      mediaNode = doc.css('manifest media').first
      mediaNode ? mediaNode["url"] : nil
    end

    def assetSwfUrl(assetId)
      config = CanvasKaltura::ClientV3.config
      return nil unless config
      "https://#{config['domain']}/kwidget/wid/_#{config['partner_id']}/uiconf_id/#{config['player_ui_conf']}/entry_id/#{assetId}"
    end

    private

    def postRequest(service, action, params)
      requestParams = "service=#{service}&action=#{action}"
      multipart_body, headers = Multipart::Post.new.prepare_query(params)
      response = sendRequest(
        Net::HTTP::Post.new("#{@endpoint}/?#{requestParams}", headers),
        multipart_body
      )
      Nokogiri::XML(response.body).css('result').first
    end

    def getRequest(service, action, params)
      requestParams = "service=#{service}&action=#{action}"
      params.each do |key, value|
        next if value.nil?
        requestParams += "&#{URI.escape(key.to_s)}=#{URI.escape(value.to_s)}"
      end
      response = sendRequest(Net::HTTP::Get.new("#{@endpoint}/?#{requestParams}"))
      Nokogiri::XML(response.body).css('result').first
    end

    # FIXME: SSL verifification should not be turned off, but since we're just
    # turning on HTTPS everywhere for kaltura, we're being gentle about it in
    # the first pass
    def sendRequest(request, body=nil)
      response = nil
      CanvasKaltura.with_timeout_protector(fallback_timeout_length: 30) do
        http = Net::HTTP.new(@host, Net::HTTP.https_default_port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        response = http.request(request, body)
      end
      raise Timeout::Error unless response
      response
    end
  end
end
