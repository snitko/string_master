class StringMaster

  require "erb"
  require "action_view"
 
  include ERB::Util
  include ActionView::Helpers

  attr_reader(:modified_string)
  alias :string :modified_string

  def initialize(string)
    @initial_string  = String.new(string.html_safe)
    @modified_string = String.new(string.html_safe)
    yield(self) if block_given?
  end

  # Closes all unclosed tags that need to be closed (i.e. skips <img>, <br> etc.)
  def close_tags
    text = @modified_string

    open_tags = []
    text.scan(/<([a-zA-Z0-9]+?)(\s[^>]*)?>/).each { |t| open_tags.unshift(t[0]) }
    text.scan(/<\/\s*?([a-zA-Z0-9]+)\s*?>/).each  { |t| open_tags.slice!(open_tags.index(t[0])) unless open_tags.index(t[0]).nil? }
    open_tags.each { |t| text += "</#{t}>" unless %w(img br hr).include?(t.to_s) }
    
    @modified_string = text
    return self
  end


  # escapes all tags except the ones, that are listed in :except option
  def html_escape(options={})
    except = options[:except] || %w()
    close_tags
    @modified_string.gsub!(/<\/?([a-zA-Z0-9]*?)(\s[^>]*)?>/) do |tag|
      if except.include?($1)
        # Really sanitizes attributes only here
        sanitize(tag, :tags => except, :attributes => %w(href src lang))
      else
        h(tag)
      end
    end
    self
  end

  # Creates <img> tags for all urls that look like images.
  def urls_to_images(options = {})
    wrap_with    = options[:wrap_with]    || ['','']
    html_options = options[:html_options] || ''
    @modified_string.gsub!(
      /(\s|^|\A|\n|\t|\r)(http:\/\/.*?\.(jpg|jpeg|png|gif|JPG|JPEG|PNG|GIF))([,.])?(\s|$|\n|\Z|\t|\r)/,
      "#{wrap_with[0]}<img src=\"\\2\" alt=\"\" #{html_options}/>\\5#{wrap_with[1]}"
    )
    self
  end

  # Creates <a> tags for all urls.
  # IMPORTANT: make sure you've used #urls_to_images method first
  # if you wanted all images urls to become <img> tags.
  def urls_to_links(options = {})
    wrap_with = options[:wrap_with] || ['','']
    html_options = options[:html_options] || ''
    @modified_string.gsub!(
      /(\s|^|\A|\n|\t|\r)(http:\/\/.*?)([,.])?(\s|$|\n|\Z|\t|\r|<)/,
      '\1<a href="\2" ' + html_options + '>\2</a>\3\4'
    )
    self
  end

  # Breaks words that are longer than 'length'
  def break_long_words(length=75, &block)
    @modified_string.gsub!(/<a [^>]+>|<img [^>]+>|([^\s^\n^\^^\A^\t^\r<]{#{length},}?)|<\/a>/) do |s|
      if $1
        ns = block_given? ? yield($1) : $1
        last_pos, result_string = 0, ''
          while string = ns[last_pos..(last_pos + length)]
          result_string += string + ' '
          last_pos += (length + 1)
        end
        result_string
      else
        s
      end
    end
    self
  end

  # Cuts a string starting at 'cut_at' if the string is longer than 'length'.
  # Appends characters (if specified in :append) to the end of the cut string.
  def cut(length, cut_at, options = {})
    append = options[:append] || ''
    @modified_string.size > (length) ? @modified_string = @modified_string.mb_chars[0...cut_at] + append : @modified_message
    self
  end

  def newlines_to_br
    @modified_string.gsub!("\n", "<br/>")
    self
  end

  # Finds lines of text that satisfy a 'regexp' and wraps them into an
  # opening and closing 'tag'. Best example of usage is #wrap_code.
  def wrap_lines(tag, regexp)
    code_open = false; result = ""
    @modified_string.each_line do |line|
      if line =~ /\A\s{4}/
        result += "<#{tag}>" unless code_open
        code_open = true
        result += line.sub(regexp, '')
      else
        result.chomp!
        result += "</#{tag}>\n" if code_open
        code_open = false
        result += line
      end
    end
    @modified_string = result
    self
  end

  # Finds all lines that start with 4 spaces and wraps them into <code> tags.
  def wrap_code
    wrap_lines("code", /\A\s{4}/) # wrap lines already returns `self`
  end

  def wrap_inline_code(opening_tag="<span class=\"inlineCode\">", closing_tag="</span>")
    @modified_string.gsub!(/`(.+?)`/, opening_tag + '\1' + closing_tag)
    self
  end

  def to_s
    modified_string.html_safe
  end

end

