require "yaml"
require "dbdoc/constants"

module Dbdoc
  class Config
    FILE_NAME = "config.yml".freeze
    DEFAULT_FILE = File.join(DBDOC_HOME, "config", "default.yml")

    class << self
      # Be default gem will try to load config file in user's project folder.
      # Then user's config (or empty object) will be merge with the default config
      # from gem's folder.
      #
      def load
        user_config = File.exist?(user_file) ? YAML.safe_load(File.read(user_file)) : {}
        default_config = YAML.safe_load(File.read(DEFAULT_FILE))

        default_config.merge(user_config)
      end

      private

      def user_file
        File.join(Dir.pwd, FILE_NAME)
      end
    end
  end
end
