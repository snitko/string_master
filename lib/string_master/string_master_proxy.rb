module StringMasterProxy

  # This should be used on a String to get access to
  # StringMaster's methods. Two notations are available:
  # - Block notation:
  #     String#prep { |s| s.cut(...); s.break_long_words }
  # - Chained methods notation
  #     String#prep.cut(...).break_long_words(...)
  #
  # Beware that in (1) a String object is returned, while in (2) a StringMaster object is returned
  # (although StringMaster has a #to_s method).
  def prep
    if block_given?
      @string_master ||= StringMaster.new(self)
      self.replace yield(@string_master).to_s
      self
    else
      StringMaster.new(self)
    end
  end

end

class String
  include StringMasterProxy
end
