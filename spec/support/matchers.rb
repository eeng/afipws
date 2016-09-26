RSpec::Matchers.define :match_xpath do |xpath, expected_value|
  match do |xml|
    @xml = Nokogiri::XML xml
    @xml.remove_namespaces!
    @xml.xpath(xpath).text.should == expected_value.to_s
  end

  failure_message_for_should do |actual|
    "expected xpath '#{xpath}' with value '#{expected_value}' in doc:\n#{@xml}"
  end
end