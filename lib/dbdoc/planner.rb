module Dbdoc
  class Planner
    def initialize(config: {})
      @config = Dbdoc::Config.load.merge(config)
    end

    def plan(path: Dir.pwd, verbose: true)
      path ||= Dir.pwd

      puts "--> Planning"
    end
  end
end
