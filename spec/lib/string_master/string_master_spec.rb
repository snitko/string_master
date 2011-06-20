require "spec_helper"

describe StringMaster do
  
  it "closes unclosed tags" do
    parser = StringMaster.new("<b>Hello,<i>world</b>")
    parser.close_tags.string.should == '<b>Hello,<i>world</b></i>'
  end

  it "escapes html except for some of the allowed tags" do
    parser = StringMaster.new('<img src="#" style="border: solid 1px green;"><b>Hello</b>')
    parser.html_escape(:except => %w(img)).string.should == '<img src="#">&lt;b&gt;Hello&lt;/b&gt;'
  end

  it "makes images of urls that end with .jpg and other image extensions" do
    parser = StringMaster.new('Hello, this is my photo http://image.com/image.jpg, yeah baby')
    parser.urls_to_images(:wrap_with => ['<p>', '</p>'], :html_options => 'class="ico"').string.should == 
      'Hello, this is my photo<p><img src="http://image.com/image.jpg" alt="" class="ico"/> </p>yeah baby'
  end

  it "makes links of urls" do
    # example 1
    parser = StringMaster.new('Hello, this is my homepage http://url.com, yeah baby')
    parser.urls_to_links.string.should ==
      'Hello, this is my homepage <a href="http://url.com" >http://url.com</a>, yeah baby'
    
    # example 2
    parser = StringMaster.new("http://localhost:3000/\nhttp://localhost:3000/")
    parser.urls_to_links.string.should ==
      "<a href=\"http://localhost:3000/\" >http://localhost:3000/</a>\n<a href=\"http://localhost:3000/\" >http://localhost:3000/</a>"

    # example 3
    parser = StringMaster.new('http://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png<br>')
    parser.urls_to_links.string.should == '<a href="http://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png" >http://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png</a><br>'
  end

  it "highlights code" do
    begin
      require 'uv'
      parser = StringMaster.new('<code>print "hello, world!"</code>')
      parser.highlight_code.string.should == '<pre class="active4d">print <span class="String"><span class="String">&quot;</span>hello, world!<span class="String">&quot;</span></span>' + "\n</pre>"
    rescue LoadError
      pending "This test is skipped because 'ultraviolet' gem is not installed. If you wish to highlight code in a string, install this gem manually. Note that it fails to build native extensions with ruby 1.9.x so it's only possible to use it with ruby 1.8.x"
    end

  end

  it "breaks long words" do
    long_string = 'l'; 1.upto(80) { |i| long_string << "o" }; long_string << "ng"
    parser = StringMaster.new(long_string)
    # fix extra space at the end of the line
    parser.break_long_words.string.should == "loooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo oooooong"
  end

  it "handles 'a' tags when attempt to break long words" do
    long_string = '<a href="loooooong>loooooong</a>'
    parser = StringMaster.new(long_string)
    parser.break_long_words(5).string.should == '<a href="loooooong>loooo oong</a>'
  end

  it "handles 'img' tags when attempt to break long words" do
    long_string = '<img src="image.gif" alt="looooooooooooongalt"/>'
    parser = StringMaster.new(long_string)
    parser.break_long_words(5).string.should == '<img src="image.gif" alt="looooooooooooongalt"/>'
  end

  it "cuts too long string and appends (if specified) characters to its end" do
    parser = StringMaster.new("This is quite a long text")
    parser.cut(11, 7, :append => '...').string.should == "This is..."
  end

  it "allows to use block notation" do
    parser = StringMaster.new('http://images.com/image.jpg <b>Hello http://url.com </b>') do |p|
      p.urls_to_images.urls_to_links(:html_options => 'target="_blank"')
    end
    parser.string.should ==
      "<img src=\"http://images.com/image.jpg\" alt=\"\" /> <b>Hello <a href=\"http://url.com\" target=\"_blank\">http://url.com</a> </b>"
  end



end
