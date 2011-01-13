class String
  def camelize first_letter_in_uppercase = true
    if first_letter_in_uppercase
      gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    else
      to_s[0].chr.downcase + self.camelize[1..-1]
    end
  end
end