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

module InstrumentTLSCiphers
  @without_tls_metrics = false

  module_function

  def without_tls_metrics
    @without_tls_metrics, old_value = true, @without_tls_metrics
    yield
  ensure
    @without_tls_metrics = old_value
  end

  def connected(ssl_socket)
    return unless ssl_socket.hostname

    cipher, tls_version, = ssl_socket.cipher

    return unless cipher

    # rubocop:disable Lint/NoHighCardinalityStatsdTags -- The hostname tag is needed tounderstand which schools to contact if issues occur
    unless @without_tls_metrics
      InstStatsd::Statsd.distributed_increment("canvas.tls.connection",
                                               tags: { hostname: ssl_socket.hostname,
                                                       cipher:,
                                                       tls_version: })
    end
    # rubocop:enable Lint/NoHighCardinalityStatsdTags
    Rails.logger.info("#{tls_version} connection established with #{ssl_socket.hostname} using cipher #{cipher}")
  end
end

module InstrumentTLSCiphersInNetProtocol
  def ssl_socket_connect(ssl_socket, _timeout)
    super

    InstrumentTLSCiphers.connected(ssl_socket)
  end
end

module InstrumentTLSCiphersInNetLDAP
  module ClassMethods
    def wrap_with_ssl(*)
      super.tap { |ssl_socket| InstrumentTLSCiphers.connected(ssl_socket) }
    end
  end
end

Autoextend.hook(:"Net::Protocol", InstrumentTLSCiphersInNetProtocol, method: :prepend)
Autoextend.hook(:"Net::LDAP::Connection", InstrumentTLSCiphersInNetLDAP::ClassMethods, method: :prepend, singleton: true)
