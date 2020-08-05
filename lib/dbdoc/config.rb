# frozen_string_literal: true

require "yaml"
require "dbdoc/constants"

module Dbdoc
  # Dbdoc::Config class knows how to load the default config from the
  # dbdoc gem folder. Later, if needed, this class could be used to merge
  # user-defined config with the default one.
  class Config
    DEFAULT_FILE = File.join(DBDOC_HOME, "config", "default.yml")

    class << self
      def load
        YAML.safe_load(File.read(DEFAULT_FILE))
      end
    end
  end
end
