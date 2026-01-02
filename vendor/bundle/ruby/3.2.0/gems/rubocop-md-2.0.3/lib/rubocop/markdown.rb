# frozen_string_literal: true

require "rubocop/markdown/version"
require "pathname"

module RuboCop
  # Plugin to run Rubocop against Markdown files
  module Markdown
    PROJECT_ROOT   = Pathname.new(__dir__).parent.parent.expand_path.freeze
    CONFIG_DEFAULT = PROJECT_ROOT.join("config", "default.yml").freeze

    require_relative "markdown/preprocess"
    require_relative "markdown/rubocop_ext" if defined?(::RuboCop::ProcessedSource)
    require_relative "markdown/plugin"
  end
end
