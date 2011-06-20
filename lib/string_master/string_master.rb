class StringMaster

  require "erb"
  require "action_view"
 
  include ERB::Util
  include ActionView::Helpers

  attr_reader(:modified_string)
  alias :string :modified_string

  def initialize(string)
    @initial_string  = string
    @modified_string = string
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

  # Highlights code using 'uv' library.
  # Make sure you have ultraviolet gem installed.
  def highlight_code(options={})
    begin
      require 'uv'
    rescue LoadError
      raise LoadError, "Gem 'ultraviolet' is required to highlight code. Please install the gem. Note that it fails to build native extensions with ruby 1.9.x so it's only possible to use it with ruby 1.8.x\n\n "
    end

    wrap_with = options[:wrap_with] || ['','']
    text = @modified_string

    languages_syntax_list = File.readlines(
      File.expand_path(File.dirname(__FILE__) + '/../config/languages_syntax_list')
    ).map { |l| l.chomp }

    text.gsub!(/<code(\s*?lang=["']?(.*?)["']?)?>(.*?)<\/code>/) do
      if languages_syntax_list.include?($2)
        lang = $2
      else
        lang = 'ruby'
      end
      unless $3.blank?
        result = Uv.parse($3.gsub('<br/>', "\n").gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', '"'), 'xhtml', lang, false, 'active4d')
        "#{wrap_with[0].gsub('$lang', lang)}#{result}#{wrap_with[1]}"
      end
    end

    # TODO: split string longer than 80 characters

    @modified_string = text
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
    @modified_string.size > (length) ? @modified_string = @modified_string.mb_chars[0...cut_at] + '...' : @modified_message
    self
  end

  def newlines_to_br
    @modified_string.gsub!("\n", "<br/>")
    self
  end

  def to_s
    modified_string
  end

end

