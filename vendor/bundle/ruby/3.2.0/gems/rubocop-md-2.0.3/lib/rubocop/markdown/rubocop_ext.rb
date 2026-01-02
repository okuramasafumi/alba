# frozen_string_literal: true

module RuboCop
  module Markdown # :nodoc:
    # See https://github.com/github-linguist/linguist/blob/8c380f360ce00b95fa08d14ce0ebccd481af1b33/lib/linguist/languages.yml#L4088-L4098
    # Keep in sync with config/default.yml
    MARKDOWN_EXTENSIONS = %w[
      .md
      .livemd
      .markdown
      .mdown
      .mdwn
      .mkd
      .mkdn
      .mkdown
      .ronn
      .scd
      .workbook
    ].freeze

    # A list of cops that could produce offenses in commented lines
    MARKDOWN_OFFENSE_COPS = %w[Lint/Syntax].freeze

    class << self
      attr_accessor :config_store

      def markdown_file?(file)
        MARKDOWN_EXTENSIONS.include?(File.extname(file))
      end
    end
  end
end

RuboCop::Runner.prepend(Module.new do
  # Set config store for Markdown
  def get_processed_source(...)
    RuboCop::Markdown.config_store = @config_store unless RuboCop::Markdown.config_store

    super
  end

  # Do not cache markdown files, 'cause cache doesn't know about processing.
  # NOTE: we should involve preprocessing in RuboCop::CachedData#deserialize_offenses
  def file_offense_cache(file, ...)
    return yield if RuboCop::Markdown.markdown_file?(file)

    super
  end

  def file_finished(file, offenses, ...)
    return super unless RuboCop::Markdown.markdown_file?(file)

    # Run Preprocess.restore if file has been autocorrected
    if @options[:auto_correct] || @options[:autocorrect]
      RuboCop::Markdown::Preprocess.restore_and_save!(file)
    end

    super
  end
end)

RuboCop::Cop::Commissioner::InvestigationReport.prepend(Module.new do
  # Skip offenses reported for ignored MD source (trailing whitespaces, etc.)
  def offenses
    @offenses ||= begin
      marker_comment = "##{RuboCop::Markdown::Preprocess::MARKER}"
      offenses_per_cop.flatten(1).reject do |offense|
        next if RuboCop::Markdown::MARKDOWN_OFFENSE_COPS.include?(offense.cop_name)

        offense.location.source_line.start_with?(marker_comment)
      end
    end
  end
end)

# Allow Rubocop to analyze markdown files
RuboCop::TargetFinder.prepend(Module.new do
  def ruby_file?(file, ...)
    super || RuboCop::Markdown.markdown_file?(file)
  end
end)

# Extend ProcessedSource#parse with pre-processing
RuboCop::ProcessedSource.prepend(Module.new do
  def parse(src, ...)
    # only process Markdown files
    src = RuboCop::Markdown::Preprocess.new(path).call(src) if
      path && RuboCop::Markdown.markdown_file?(path)
    super
  end
end)
