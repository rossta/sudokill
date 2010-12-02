module Sudocoup

  class Logger
    @@log = true

    def self.log(message)
      puts message if log?
    end

    def self.log?
      @@log
    end

    def self.suppress_logging!
      @@log = false
    end

  end

end