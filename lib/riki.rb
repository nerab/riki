require 'riki/version'
require 'riki/errors'
require 'riki/base'
require 'riki/page'
require 'riki/category'
require 'riki/log_formatter'
require 'preferences/base'
require 'active_support/core_ext/module/attribute_accessors'

module Riki
  mattr_accessor :logger

  unless @@logger
    @@logger = Logger.new(STDERR)
    @@logger.level = Logger::WARN
    @@logger.formatter = LogFormatter.new
  end
end
