require 'logger'
module Sudokill

  module Logger
    @@log = true

    @@logger = nil

    def self.logger=(logger)
      @@logger = logger
    end

    def self.logger
      @@logger
    end

    def self.log(message)
      return unless log?
      if logger
        logger.info message
      else
        puts message
      end
    end

    def self.log?
      @@log
    end

    def self.suppress_logging!
      @@log = false
    end

  end

end