require 'test/unit'
require 'nokogiri'
require 'open-uri'
require 'simplecov'
require 'simplecov-cobertura'

class CoberturaFormatterTest < Test::Unit::TestCase
  def setup
    SimpleCov.enable_coverage :branch
    SimpleCov.coverage_dir "tmp"
    @result = SimpleCov::Result.new({
      "#{__FILE__}" => {
        "lines" => [1, 1, 1, nil, 1, nil, 1, 0, nil, 1, nil, nil, nil],
        "branches" => {
          [:if, 0, 3, 4, 3, 21] =>
          {[:then, 1, 3, 4, 3, 10] => 0, [:else, 2, 3, 4, 3, 21] => 1},
            [:if, 3, 5, 4, 5, 26] =>
          {[:then, 4, 5, 16, 5, 20] => 1, [:else, 5, 5, 23, 5, 26] => 0},
            [:if, 6, 7, 4, 11, 7] =>
          {[:then, 7, 8, 6, 8, 10] => 0, [:else, 8, 10, 6, 10, 9] => 1},
            [:if, 9, 12, 4, 12, 15] =>
          {[:then, 10, 12, 6, 12, 10] => 1, [:else, 11, 12, 13, 12, 15] => 0},
            [:if, 12, 13, 4, 13, 20] =>
          {[:then, 13, 13, 6, 13, 15] => 1, [:else, 14, 13, 18, 13, 20] => 0},
            [:if, 15, 15, 4, 15, 25] =>
          {[:then, 16, 15, 6, 15, 20] => 0, [:else, 17, 15, 23, 15, 25] => 0}
        }
      }
    })
    @formatter = SimpleCov::Formatter::CoberturaFormatter.new
  end

  def teardown
    SimpleCov.groups.clear
  end

  def test_format_save_file
    xml = @formatter.format(@result)
    result_path = File.join(SimpleCov.coverage_path, SimpleCov::Formatter::CoberturaFormatter::RESULT_FILE_NAME)
    assert_not_empty(xml)
    assert_equal(xml, IO.read(result_path))
  end

  def test_format_save_custom_filename
    xml = SimpleCov::Formatter::CoberturaFormatter.new(result_file_name: 'cobertura.xml').format(@result)
    result_path = File.join(SimpleCov.coverage_path, 'cobertura.xml')
    assert_not_empty(xml)
    assert_equal(xml, IO.read(result_path))
  end

  def test_terminal_output
    output, _ = capture_output { @formatter.format(@result) }
    result_path = File.join(SimpleCov.coverage_path, SimpleCov::Formatter::CoberturaFormatter::RESULT_FILE_NAME)
    output_regex = /Coverage report generated for #{@result.command_name} to #{result_path}.\nLine Coverage: (.*)\nBranch Coverage: (.*)/
    assert_match(output_regex, output)
  end

  # Rather than support HTTPS the HTTP client was removed from libxml2 / xmllint:
  # https://gitlab.gnome.org/GNOME/libxml2/-/issues/160
  # I am not sure what this means for Nokogiri or this issue, but it certainly means something will change soon.
  # Disable this test until it becomes clear what the new behavior should be.
  # def test_format_dtd_validates
  #   xml = @formatter.format(@result)
  #   options = Nokogiri::XML::ParseOptions::DTDLOAD
  #   doc = Nokogiri::XML::Document.parse(xml, nil, nil, options)
  #   assert_empty doc.external_subset.validate(doc)
  # end

  def test_no_groups
    xml = @formatter.format(@result)
    doc = Nokogiri::XML::Document.parse(xml)

    coverage = doc.xpath '/coverage'
    assert_equal '0.8571', coverage.attribute('line-rate').value
    assert_equal '0.4167', coverage.attribute('branch-rate').value
    assert_equal '6', coverage.attribute('lines-covered').value
    assert_equal '7', coverage.attribute('lines-valid').value
    assert_equal '5', coverage.attribute('branches-covered').value
    assert_equal '12', coverage.attribute('branches-valid').value
    assert_equal '0', coverage.attribute('complexity').value
    assert_equal '0', coverage.attribute('version').value
    assert_not_empty coverage.attribute('timestamp').value

    sources = doc.xpath '/coverage/sources/source'
    assert_equal 1, sources.length
    assert_equal 'simplecov-cobertura', File.basename(sources.first.text)

    packages = doc.xpath '/coverage/packages/package'
    assert_equal 1, packages.length
    package = packages.first
    assert_equal 'simplecov-cobertura', package.attribute('name').value
    assert_equal '0.8571', package.attribute('line-rate').value
    assert_equal '0.4167', package.attribute('branch-rate').value
    assert_equal '0', package.attribute('complexity').value

    classes = doc.xpath '/coverage/packages/package/classes/class'
    assert_equal 1, classes.length
    clazz = classes.first
    assert_equal 'test/simplecov-cobertura_test.rb', clazz.attribute('name').value
    assert_equal 'test/simplecov-cobertura_test.rb', clazz.attribute('filename').value
    assert_equal '0.8571', clazz.attribute('line-rate').value
    assert_equal '0.4167', clazz.attribute('branch-rate').value
    assert_equal '0', clazz.attribute('complexity').value

    lines = doc.xpath '/coverage/packages/package/classes/class/lines/line'
    assert_equal 7, lines.length
    first_line = lines.first
    assert_equal '1', first_line.attribute('number').value
    assert_equal 'false', first_line.attribute('branch').value
    assert_equal '1', first_line.attribute('hits').value
    last_line = lines.last
    assert_equal '10', last_line.attribute('number').value
    assert_equal 'true', last_line.attribute('branch').value
    assert_equal '1', last_line.attribute('hits').value
  end

  def test_groups
    SimpleCov.add_group('test_group', 'test/')

    xml = @formatter.format(@result)
    doc = Nokogiri::XML::Document.parse(xml)

    coverage = doc.xpath '/coverage'
    assert_equal '0.8571', coverage.attribute('line-rate').value
    assert_equal '0.4167', coverage.attribute('branch-rate').value
    assert_equal '6', coverage.attribute('lines-covered').value
    assert_equal '7', coverage.attribute('lines-valid').value
    assert_equal '5', coverage.attribute('branches-covered').value
    assert_equal '12', coverage.attribute('branches-valid').value
    assert_equal '0', coverage.attribute('complexity').value
    assert_equal '0', coverage.attribute('version').value
    assert_not_empty coverage.attribute('timestamp').value

    sources = doc.xpath '/coverage/sources/source'
    assert_equal 1, sources.length
    assert_equal 'simplecov-cobertura', File.basename(sources.first.text)

    packages = doc.xpath '/coverage/packages/package'
    assert_equal 1, packages.length
    package = packages.first
    assert_equal 'test_group', package.attribute('name').value
    assert_equal '0.8571', package.attribute('line-rate').value
    assert_equal '0.4167', package.attribute('branch-rate').value
    assert_equal '0', package.attribute('complexity').value

    classes = doc.xpath '/coverage/packages/package/classes/class'
    assert_equal 1, classes.length
    clazz = classes.first
    assert_equal 'test/simplecov-cobertura_test.rb', clazz.attribute('name').value
    assert_equal 'test/simplecov-cobertura_test.rb', clazz.attribute('filename').value
    assert_equal '0.8571', clazz.attribute('line-rate').value
    assert_equal '0.4167', clazz.attribute('branch-rate').value
    assert_equal '0', clazz.attribute('complexity').value

    lines = doc.xpath '/coverage/packages/package/classes/class/lines/line'
    assert_equal 7, lines.length
    first_line = lines.first
    assert_equal '1', first_line.attribute('number').value
    assert_equal 'false', first_line.attribute('branch').value
    assert_equal '1', first_line.attribute('hits').value
    last_line = lines.last
    assert_equal '10', last_line.attribute('number').value
    assert_equal 'true', last_line.attribute('branch').value
    assert_equal '1', last_line.attribute('hits').value
  end

  def test_supports_root_project_path
    old_root = SimpleCov.root
    SimpleCov.root("/tmp")
    expected_base = old_root[1..-1] # Remove leading "/"

    xml = @formatter.format(@result)
    doc = Nokogiri::XML::Document.parse(xml)

    classes = doc.xpath '/coverage/packages/package/classes/class'
    assert_equal 1, classes.length
    clazz = classes.first
    assert_equal "../#{expected_base}/test/simplecov-cobertura_test.rb", clazz.attribute('name').value
    assert_equal "../#{expected_base}/test/simplecov-cobertura_test.rb", clazz.attribute('filename').value
  ensure
    SimpleCov.root(old_root)
  end
end
