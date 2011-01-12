RSpec::Matchers.define :match_xpath do |xpath, expected_text|
  match do |xml|
    xml = Nokogiri::XML xml
    xml.xpath(xpath).text.should == expected_text
  end
end
