# frozen_string_literal: true

require "fileutils"

# Useful helpers for writing specs
#
module Helpers
  SPEC_TMP_FOLDER = File.expand_path("../tmp", __dir__)

  def tmp_folder(fixture_folder_name)
    File.join(Helpers::SPEC_TMP_FOLDER, fixture_folder_name)
  end

  def with_dbdoc_folder(fixture_folder_name)
    fixture_folder = File.expand_path("../fixtures/#{fixture_folder_name}", __dir__)

    Dir.mkdir(SPEC_TMP_FOLDER) unless Dir.exist?(SPEC_TMP_FOLDER)

    FileUtils.cp_r(fixture_folder, SPEC_TMP_FOLDER)

    yield
  ensure
    FileUtils.rm_r(SPEC_TMP_FOLDER) if Dir.exist?(SPEC_TMP_FOLDER)
  end
end
