require "spec_helper"

describe StringMaster do
  
  it "closes unclosed tags" do
    parser = StringMaster.new("<b>Hello,<i>world</b>")
    parser.close_tags.string.should == '<b>Hello,<i>world</b></i>'
  end

  it "escapes html except for some of the allowed tags" do
    parser = StringMaster.new('<img src="#" style="border: solid 1px green;"><b>Hello</b>')
    parser.html_escape(:except => %w(img)).string.should == '<img src="#">&lt;b&gt;Hello&lt;/b&gt;'
    parser = StringMaster.new('<i>hello</i> <b>world</b>')
    parser.html_escape(:except => %w(b)).to_s.should == '&lt;i&gt;hello&lt;/i&gt; <b>world</b>'
    parser = StringMaster.new('<a href="http://google.com">hello</a> <b>world</b>')
    parser.html_escape(:except => %w(a)).to_s.should == '<a href="http://google.com">hello</a> &lt;b&gt;world&lt;/b&gt;'
    parser = StringMaster.new('<a href="https://google.com">hello</a> <b>world</b>')
    parser.html_escape(:except => %w(a)).to_s.should == '<a href="https://google.com">hello</a> &lt;b&gt;world&lt;/b&gt;'
  end

  it "makes images of urls that end with .jpg and other image extensions" do
    parser = StringMaster.new('Hello, this is my photo http://image.com/image.jpg, yeah baby')
    parser.urls_to_images(:wrap_with => ['<p>', '</p>'], :html_options => 'class="ico"').string.should == 
      'Hello, this is my photo<p><img src="http://image.com/image.jpg" alt="" class="ico"/> </p>yeah baby'

    # use https
    parser = StringMaster.new('Hello, this is my photo https://image.com/image.jpg, yeah baby')
    parser.urls_to_images(:wrap_with => ['<p>', '</p>'], :html_options => 'class="ico"').string.should == 
      'Hello, this is my photo<p><img src="https://image.com/image.jpg" alt="" class="ico"/> </p>yeah baby'
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

    # example 4, with https
    parser = StringMaster.new('https://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png<br>')
    parser.urls_to_links.string.should == '<a href="https://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png" >https://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png</a><br>'
  end

  it "wraps code in <code> tags" do
    code = <<CODE
I have a piece of code
    def say_hello
      puts "hello world"
      return true
    end
and here's what my code looks like.
CODE
    StringMaster.new(code).wrap_code.to_s.should == <<WRAPPED_CODE
I have a piece of code<code>def say_hello
&nbsp;&nbsp;puts "hello world"
&nbsp;&nbsp;return true
end</code>and here's what my code looks like.
WRAPPED_CODE
  end

  it "wraps code in <code> and adds a closing tag even if regexp for closing tag doesn't match" do
    code = <<CODE
I have a piece of code
    def say_hello
      puts "hello world"
      return true
    end
CODE
    StringMaster.new(code).wrap_code.to_s.should == <<WRAPPED_CODE
I have a piece of code<code>def say_hello
&nbsp;&nbsp;puts "hello world"
&nbsp;&nbsp;return true
end</code>
WRAPPED_CODE
  end

  it "wraps inline code into <span class=\"inlineCode\"></span> tags" do
    code = "I have a variable called `a` and it has a `nil` value"
    parser = StringMaster.new(code)
    parser.wrap_inline_code.to_s.should == "I have a variable called <span class=\"inlineCode\">a</span> and it has a <span class=\"inlineCode\">nil</span> value"
  end

  it "wraps code in backticks stretched across multiple lines" do
    code = "`hello\nworld`"
    parser = StringMaster.new(code)
    parser.wrap_backticks_code.to_s.should == "<code>hello\nworld</code>"
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

    parser = StringMaster.new('https://images.com/image.jpg <b>Hello https://url.com </b>') do |p|
      p.urls_to_images.urls_to_links(:html_options => 'target="_blank"')
    end
    parser.string.should ==
      "<img src=\"https://images.com/image.jpg\" alt=\"\" /> <b>Hello <a href=\"https://url.com\" target=\"_blank\">https://url.com</a> </b>"
  end

  it "replaces newline characters with <br/> tags" do
    parser = StringMaster.new("This is quite a\n long text")
    parser.wrap_code.newlines_to_br.to_s.should == "This is quite a<br/> long text"
  end

end
