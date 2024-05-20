# frozen_string_literal: true

#
# Copyright (C) 2011 - present Instructure, Inc.
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

# A small wrapper around the CutyCapt binary.
#
# Requires a config in dynamic settings private/canvas/cutycapt.yml that looks like this:
#
# production:
#   path: /usr/bin/cutycapt
#   delay: 3000
#   timeout: 30000
#   display: ':0'
#   screencap_service:
#     url: https://foo.bar/baz
#     key: abcdefg
#
# delay is how many ms to wait before taking the snapshot (to let the page finish rendering)
# display is whatever display cutycapt should use. (You should probably use Xvfb.)
#
# The `screencap_service` will bypass using the Cuty binary altogether, and send a request
# to the given url with a query param of `url=` and the website to snapshot, and a header
# X-API-Key with the given key.

class CutyCapt
  CUTYCAPT_DEFAULTS = {
    delay: 3000,
    timeout: 60_000,
    ip_blacklist: ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "169.254.169.254", "127.0.0.0/8"],
    domain_blacklist: [],
    allowed_schemes: ["http", "https"],
    lang: "en,*;q=0.9"
  }.freeze

  cattr_writer :config

  def self.config
    return @@config if defined?(@@config) && @@config

    setting = begin
      consul_config = DynamicSettings.find(tree: :private)["cutycapt.yml"]
      (consul_config && YAML.safe_load(consul_config).with_indifferent_access) || ConfigFile.load("cutycapt") || {}
    end
    setting = setting.symbolize_keys
    @@config = CUTYCAPT_DEFAULTS.merge(setting).with_indifferent_access
    process_config
    @@config = nil unless @@config[:path] || @@config[:screencap_service]
    @@config
  end

  def self.screencap_service
    return @@screencap_service if defined?(@@screencap_service) && @@screencap_service
    return nil unless @@config[:screencap_service]

    @@screencap_service = Services::ScreencapService.new(@@config[:screencap_service])
    @@screencap_service
  end

  def self.process_config
    @@config[:ip_blacklist] = @@config[:ip_blacklist].map { |ip| IPAddr.new(ip) } if @@config[:ip_blacklist]
    @@config[:domain_blacklist] = @@config[:domain_blacklist].map { |domain| Resolv::DNS::Name.create(domain) } if @@config[:domain_blacklist]
  end

  def self.logger
    Rails.logger
  end

  def self.enabled?
    !config.nil?
  end

  def self.verify_url(url)
    config = self.config

    uri = URI.parse(url)
    unless config[:allowed_schemes]&.include?(uri.scheme)
      logger.warn("Skipping non-http[s] URL: #{url}")
      return false
    end

    dns_host = Resolv::DNS::Name.create(uri.host)
    if config[:domain_blacklist]&.any? { |bl_host| dns_host == bl_host || dns_host.subdomain_of?(bl_host) }
      logger.warn("Skipping url because of blacklisted domain: #{url}")
      return false
    end

    addresses = Resolv.getaddresses(uri.host)
    return false if addresses.blank?

    if config[:ip_blacklist] && addresses.any? { |address| config[:ip_blacklist].any? { |cidr| cidr.include?(address) rescue false } }
      logger.warn("Skipping url because of blacklisted IP address: #{url}")
      return false
    end

    true
  end

  def self.cuty_arguments(path, url, img_file, format, delay, timeout, lang)
    [path, "--url=#{url}", "--out=#{img_file}", "--out-format=#{format}", "--delay=#{delay}", "--max-wait=#{timeout}", "--header=Accept-Language:#{lang}"]
  end

  def self.snapshot_url(url)
    return nil unless (config = self.config)
    return nil unless verify_url(url)

    format = "png"

    tmp_file = Tempfile.new(["websnappr", ".#{format}"], encoding: "ascii-8bit")
    img_file = tmp_file.path
    success = true

    start = Time.now
    logger.info("Starting web capture of #{url}")

    if screencap_service
      success = screencap_service.snapshot_url_to_file(url, tmp_file)
    else
      # It is less secure to take screenshots from application servers, so we strongly reccomend using
      # a separate snapshot service (e.g. https://github.com/instructure/screencap) .  Local snapshotting
      # is only reccomended for development.

      tmp_file.close!

      if (pid = fork).nil?
        ENV["DISPLAY"] = config[:display] if config[:display]
        Kernel.exec(*cuty_arguments(config[:path], url, img_file, format, config[:delay], config[:timeout], config[:lang]))
      else
        begin
          Timeout.timeout(config[:timeout].to_i / 1000) do
            Process.waitpid(pid)
            unless $?.success?
              logger.error("Capture failed with code: #{$?.exitstatus}")
              success = false
            end
          end
        rescue Timeout::Error
          logger.error("Capture timed out")
          Process.kill("KILL", pid)
          Process.waitpid(pid)
          success = false
        end
      end
    end

    if success
      logger.info("Capture took #{Time.now.to_i - start.to_i} seconds")
    else
      FileUtils.rm_f(img_file)
      return nil
    end

    if block_given?
      yield img_file
      FileUtils.rm_f(img_file)
      return nil
    end

    img_file
  end

  def self.snapshot_attachment_for_url(url, **attachment_opts)
    attachment = nil
    snapshot_url(url) do |file_path|
      # this is a really odd way to get Attachment the data it needs, which
      # should probably be remedied at some point
      attachment = Attachment.create!(uploaded_data: Canvas::UploadedFile.new(file_path, "image/png"),
                                      **attachment_opts)
    end
    attachment
  end
end
