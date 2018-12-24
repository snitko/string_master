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

    parser = StringMaster.new('<a href="https://google.com">hello</a> <b>world</b><br/><br>')
    parser.html_escape(:except => %w(a br)).to_s.should == '<a href="https://google.com">hello</a> &lt;b&gt;world&lt;/b&gt;<br/><br>'

    parser = StringMaster.new('xsstest<input/onfocus=prompt(document.cookie) autofocus>')
    parser.html_escape.to_s.should == 'xsstest&lt;input/onfocus=prompt(document.cookie) autofocus&gt;'

    parser = StringMaster.new('xsstest<input/onfocus=prompt(document.cookie)autofocus>')
    parser.html_escape.to_s.should == 'xsstest&lt;input/onfocus=prompt(document.cookie)autofocus&gt;'

    parser = StringMaster.new('xsstest"><input/onfocus=prompt() autofocus /=')
    parser.html_escape.to_s.should == 'xsstest"&gt;&lt;input/onfocus=prompt() autofocus /='

    parser = StringMaster.new('xsstest"><input/onfocus=prompt() autofocus /= <img>')
    parser.html_escape.to_s.should == 'xsstest"&gt;&lt;input/onfocus=prompt() autofocus /= &lt;img&gt;'

    parser = StringMaster.new('xsstest"><input/onfocus=prompt() autofocus /= <img>')
    parser.html_escape(except: %w(img)).to_s.should == 'xsstest"&gt;&lt;input/onfocus=prompt() autofocus /= &lt;img&gt;'

    parser = StringMaster.new('aaaa"<input/autofocus/onfocus=prompt(\'textxss\')//<>>')
    parser.html_escape(except: %w(img)).to_s.should == 'aaaa"&lt;input/autofocus/onfocus=prompt(&#39;textxss&#39;)//&lt;&gt;&gt;'

    parser = StringMaster.new('aaaa"<<<<<input/autofocus/onfocus=prompt(\'textxss\')//<<<<>>>>>')
    parser.html_escape(except: %w(img)).to_s.should == 'aaaa"&lt;&lt;&lt;&lt;&lt;input/autofocus/onfocus=prompt(&#39;textxss&#39;)//&lt;&lt;&lt;&lt;&gt;>>>&gt;'

    parser = StringMaster.new('aaaa"<input<<<<input/autofocus/onfocus=prompt(\'textxss\')//<<<<hello>>>>>')
    parser.html_escape(except: %w(img)).to_s.should == 'aaaa"&lt;input&lt;&lt;&lt;&lt;input/autofocus/onfocus=prompt(&#39;textxss&#39;)//&lt;&lt;&lt;&lt;hello&gt;>>>&gt;&lt;/hello&gt;'

    parser = StringMaster.new('<img onload="do_something()">')
    parser.html_escape(except: %w(img)).to_s.should == '<img>'
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

  describe 'makes links of urls' do
    # ascii_only option - show URLs with warning about contain non-latin characters
    describe 'without ascii_only validate' do
      # example 1
      it 'when text include url' do
        parser = StringMaster.new('Hello, this is my homepage http://url.com, yeah baby')
        parser.urls_to_links(ascii_only: false).string.should ==
          'Hello, this is my homepage <a href="http://url.com" >http://url.com</a>, yeah baby'
      end

      # example 2
      it 'when text have several urls' do
        parser = StringMaster.new("http://localhost:3000/\nhttp://localhost:3000/")
        parser.urls_to_links(ascii_only: false).string.should ==
          "<a href=\"http://localhost:3000/\" >http://localhost:3000/</a>\n<a href=\"http://localhost:3000/\" >http://localhost:3000/</a>"
      end

      # example 3
      it 'when text have html tag and url' do
        parser = StringMaster.new('http://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png<br>')
        parser.urls_to_links(ascii_only: false).string.should == '<a href="http://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png" >http://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png</a><br>'
      end

      # example 4, with https
      it 'when text include https and url' do
        parser = StringMaster.new('https://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png<br>')
        parser.urls_to_links(ascii_only: false).string.should == '<a href="https://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png" >https://gyazo.com/a4c16e7a6009f40f29248ad4fed41bd3.png</a><br>'
      end

      describe 'when url contain non-latin characters and' do

        it "warning message doesn't shows" do
          parser = StringMaster.new('http://url.cоm')
          parser.urls_to_links(ascii_only: false).string.should_not ==
            '[WARNING, URL CONTAINS NON-LATIN LETTERS: http://url.cоm]'
        end

        it "non-latin url shows like a url with latin only characters" do
          parser = StringMaster.new('http://url.cоm')
          parser.urls_to_links(ascii_only: false).string.should ==
            '<a href="http://url.cоm" >http://url.cоm</a>'
        end
      end
    end

    describe 'with ascii_only validate' do
      # example 1
      it 'show warning when text include non-latin url' do
        parser = StringMaster.new('Hello, this is my homepage http://url.cоm, yeah baby')
        parser.urls_to_links(ascii_only: true).string.should ==
          'Hello, this is my homepage [WARNING, URL CONTAINS NON-LATIN LETTERS: http://url.cоm], yeah baby'
      end

      # example 2
      it 'show warning when text have several non-latin urls' do
        parser = StringMaster.new("http://lоcalhost:3000\nhttp://lоcalhost:3000")
        parser.urls_to_links(ascii_only: true).string.should ==
          "[WARNING, URL CONTAINS NON-LATIN LETTERS: http://lоcalhost:3000]\n[WARNING, URL CONTAINS NON-LATIN LETTERS: http://lоcalhost:3000]"
      end

      # example 3
      it 'show warning when text have html tag and non-latin url' do
        parser = StringMaster.new('http://gyаzo.com/a4c16e7a6009f40f29248ad4fed41bd3.png<br>')
        parser.urls_to_links(ascii_only: true).string.should == '[WARNING, URL CONTAINS NON-LATIN LETTERS: http://gyаzo.com/a4c16e7a6009f40f29248ad4fed41bd3.png]<br>'
      end

      # example 4, with https
      it 'show warning when text include https and non-latin url' do
        parser = StringMaster.new('https://gyаzo.com/a4c16e7a6009f40f29248ad4fed41bd3.png<br>')
        parser.urls_to_links(ascii_only: true).string.should == '[WARNING, URL CONTAINS NON-LATIN LETTERS: https://gyаzo.com/a4c16e7a6009f40f29248ad4fed41bd3.png]<br>'
      end

      describe 'when url contain latin characters and' do
        it "warning message doesn't shows" do
          parser = StringMaster.new('http://url.com')
          parser.urls_to_links(ascii_only: true).string.should_not ==
            '[WARNING, URL CONTAINS NON-LATIN LETTERS: http://url.cоm]'
        end

        it "latin url shows correct" do
          parser = StringMaster.new('http://url.com')
          parser.urls_to_links(ascii_only: true).string.should ==
            "<a href='http://url.com'>http://url.com</a>"
        end
      end

      describe 'when text contain' do
        it 'non-latin symbols and latin url' do
          parser = StringMaster.new('тест http://url.com')
          parser.urls_to_links(ascii_only: true).string.should ==
            "тест <a href='http://url.com'>http://url.com</a>"
        end

        it 'both symbol types and non-latin url' do
          parser = StringMaster.new('тест non-latin url http://url.cоm')
          parser.urls_to_links(ascii_only: true).string.should ==
            "тест non-latin url [WARNING, URL CONTAINS NON-LATIN LETTERS: http://url.cоm]"
        end

        it 'both symbol types both url types' do
          parser = StringMaster.new('тест non-latin url http://url.cоm и тест only-latin url https://url.com')
          parser.urls_to_links(ascii_only: true).string.should ==
            "тест non-latin url [WARNING, URL CONTAINS NON-LATIN LETTERS: http://url.cоm] и тест only-latin url <a href='https://url.com'>https://url.com</a>"
        end
      end
    end
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

  it "handles http links when attempt to break long words" do
    string_with_long_link = 'some text http://verylonglink.com other text'
    parser = StringMaster.new(string_with_long_link)
    parser.break_long_words(6).string.should == string_with_long_link
  end

  it "handles http links when attempt to break long words" do
    string_with_long_link = 'some text https://verylonglink.com other text'
    parser = StringMaster.new(string_with_long_link)
    parser.break_long_words(6).string.should == string_with_long_link
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
