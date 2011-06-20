require "spec_helper"

describe String do

  it "acts as proxy for StringMaster using #prep method" do
    "<b>This</b> is quite a long text".prep do |s|
      s.cut(11, 7, :append => '...')
      s.html_escape
    end.should == "&lt;b&gt;This...&lt;/b&gt;"
    "<b>This</b> is quite a long text".prep.cut(11, 7, :append => '...').html_escape == "&lt;b&gt;This...&lt;/b&gt;"
  end

end
