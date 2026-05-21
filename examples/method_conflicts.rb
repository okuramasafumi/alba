# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class Report
  attr_reader :format

  def initialize(format)
    @format = format
  end
end

class ResourceMethodFirstReportResource
  include Alba::Resource

  attributes :format

  def format(_report)
    'resource-format'
  end
end

class ObjectMethodFirstReportResource
  include Alba::Resource

  prefer_object_method!

  attributes :format

  def format(_report)
    'resource-format'
  end
end

report = Report.new('pdf')

puts ResourceMethodFirstReportResource.new(report).serialize
puts ObjectMethodFirstReportResource.new(report).serialize
