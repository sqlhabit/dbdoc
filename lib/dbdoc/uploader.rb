require_relative "../confluence/api"

module Dbdoc
  class Uploader
    def initialize(config: {})
      @config = Dbdoc::Config.load.merge(config)
    end

    def upload
    end
  end
end
