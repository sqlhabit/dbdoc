module Dbdoc
  class Manager
    def initialize(config: {})
      @config = Dbdoc::Config.load.merge(config)
    end

    def plan(path: Dir.pwd, verbose: true)
      path ||= Dir.pwd

      puts "--> Planning"

      true
    end

    def apply(path: Dir.pwd, verbose: true)
      path ||= Dir.pwd

      puts "--> Applying changes"

      true
    end
  end
end
