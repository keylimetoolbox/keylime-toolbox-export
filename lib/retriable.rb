# frozen_string_literal: true

require "retriable"

Retriable.configure do |c|
  c.contexts[:keylime_toolbox_api] = {
      tries: 3,
      on:    [
          Errno::ECONNREFUSED,
          Errno::ECONNRESET,
          OpenSSL::SSL::SSLError
      ]
  }
  c.contexts[:aws_api] = {
      tries:         3,
      base_interval: 1,
      on:            [
          Errno::ECONNREFUSED,
          Errno::ECONNRESET,
          Net::ReadTimeout,
          OpenSSL::SSL::SSLError
      ]
  }
end
