# frozen_string_literal: true

require "yaml"
require "dbdoc/constants"

module Dbdoc
  # Dbdoc::Config class knows how to load the default config from the
  # dbdoc gem folder. Later, if needed, this class could be used to merge
  # user-defined config with the default one.
  class Config
    def initialize(local_path: Dir.pwd)
      @local_path = local_path
    end

    def load
      config_file = File.join(@local_path, "config.yml")

      YAML.safe_load(File.read(config_file))
    end
  end
end
