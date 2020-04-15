require 'open-uri'

class Crawler
  URL = 'http://ulricknights.pun.pl'.freeze
  NBSP_SIGN = Nokogiri::HTML("&nbsp;").text.freeze
  FORUM_KEYS = %i[id title].freeze
  POST_KEYS = %i[id title msg parent_id created_by created_at].freeze
  PHOTO_KEYS = %i[id title description created_by filename file comments].freeze
  USER_KEYS = %i[id login rank name gender location page birthdate created_at].freeze
  PostStruct = Struct.new(*POST_KEYS, keyword_init: true)
  ForumStruct = Struct.new(*FORUM_KEYS, keyword_init: true)
  PhotoStruct = Struct.new(*PHOTO_KEYS, keyword_init: true)
  UserStruct = Struct.new(*USER_KEYS, keyword_init: true)


  attr_reader :username, :password, :type, :errors

  def initialize(username:, password:, type:)
    @username = username
    @password = password
    @type = type
    @agent = Mechanize.new
    @page = @agent.get(URL)
    @errors = []
  end

  def successfully_logged?
    login
    user = @agent.cookies.find { |cookie| cookie.name == 'punbb_cookie' }
    @errors.push("Invalid credentials, can't log in!") and return false unless user
    true
  end

  def call
    return false unless successfully_logged?
    case type
    when 'users'
      link = find_link("Lista użytkowników")
      collection = fetch_users(page_link: link)
    when 'boards_and_forums'
      link = find_link("Index")
      collection = fetch_boards_and_forums(link)
    when 'topics_and_posts'
      link = find_link("Index")
      @page = link.click
      forums_links = @page.links.select { |link| link.href.match?('viewforum.php?') && link.text.present? }
      collection = forums_links.reduce({}) { |acc, link| acc.merge!(parse_id(link.href) => fetch_topics_and_posts(page_link: link)) }
    when 'gallery'
      link = find_link("Galeria")
      @page = link.click
      galleries_links = @page.links.select { |link| link.href&.match?("gallery.php?") && link.attributes.parent.name == "h3" }
      collection = galleries_links.reduce({}) do |acc, link|
        acc.merge!(Struct.new(:id, :title)[parse_id(link.href, regex: /\?cid=(\w+)/), link.text] => fetch_gallery(page_link: link))
      end
    end
    Generator.new(collection: collection, type: type).call
  end

  private

  def find_link(text)
    @page.links.find { |link| link.text == text }
  end

  def find_next_page_link
    @page.links.find { |link| link.text == '--»' }
  end

  def parse_id(string, regex: /\?id=(\w+)/)
    string.to_s.match(regex)&.captures&.first
  end

  def login
    login_link = find_link("Logowanie")
    @page = login_link.click
    form = @page.forms.first
    form['req_username'] = username
    form['req_password'] = password
    form.submit
  end

  def fetch_users(collection = [], page_link:)
    return collection unless page_link
    @page = page_link.click
    users_links = @page.links.select { |link| link.href.match?('profile.php?') && link.attributes.parent.name == 'td' }
    next_page = find_next_page_link
    collection.concat(users_links.map { |link| fetch_user(link) })
    fetch_users(collection, page_link: next_page)
  end

  def fetch_user(link)
    @page = link.click
    id = parse_id(link.href)
    row = @page.parser.css('dl dd').map(&:text)
    UserStruct.new(id: id, login: row[0], rank: row[1], name: row[2], gender: row[3], location: row[4], page: row[5], birthdate: row[6], created_at: row.last)
  end

  def fetch_boards_and_forums(link)
    @page = link.click
    @page.parser.css('.blocktable').reduce({}) do |acc, board|
      board_title = board.css('h2').text
      forums = board.css('tbody tr').map do |row|
        elem = row.css('a').first
        id = parse_id(elem.attr('href'))
        title = elem.text
        ForumStruct.new(id: id, title: title)
      end
      acc.merge(board_title => forums)
    end
  end

  def fetch_topics_and_posts(collection = [], page_link:)
    return collection unless page_link
    @page = page_link.click
    next_page = find_next_page_link
    topics_links = @page.links.select { |link| link.href.match?(/viewtopic.php?|viewpoll.php?/) && !link.href.match?(/#|&/)  && link.text.present? }
    topics_links.each { |topic_link| collection.concat(fetch_posts(page_link: topic_link)) }
    fetch_topics_and_posts(collection, page_link: next_page)
  end

  def fetch_posts(collection = [], page_link:)
    return collection unless page_link
    @page = page_link.click
    next_page = find_next_page_link
    collection.concat(@page.parser.css('.blockpost').map do |post|
      elem = post.css('h2 a').first
      id = parse_id(elem.attr('href'), regex: /\?pid=(\w+)/)
      created_at = elem.text
      created_by = parse_id(post.css('.postleft a').first&.attr('href'))
      title = post.css('.postright h3').text
      msg = post.css('.postright .postmsg .bbtext').inner_html.encode('utf-8')
      PostStruct.new(id: id, title: title, msg: msg, parent_id: parse_id(page_link.href), created_by: created_by,  created_at: created_at)
    end)
    fetch_posts(collection, page_link: next_page)
  end

  def fetch_gallery(collection = [], page_link:)
    return collection unless page_link
    @page = page_link.click
    next_page = find_next_page_link
    
    titles = @page.parser.css('td').map{ |td| td.text.strip }
    photos_links = @page.links.select { |link| link.href&.match?("gallery.php?") && link.attributes.parent.name == "div" }
    collection.concat(photos_links.map { |link| fetch_photo(link) })
    fetch_gallery(collection, page_link: next_page)
  end

  def fetch_photo(link)
    @page = link.click
    doc = @page.parser

    id = parse_id(link.href, regex: /\?pid=(\w+)/)
    img = doc.css('.scrollbox img').first
    title = img.attr('title')
    filename = img.attr('alt')
    src = img.attr('src').sub('.', URL)
    base64 = create_base64(src)

    post = doc.css('.postmsg p')
    description = post[1].text
    created_by = post[2].text.gsub(NBSP_SIGN, '').split(':').last

    comments = fetch_photo_comments(doc)
    PhotoStruct.new(id: id, title: title, description: description, created_by: created_by, filename: filename, file: base64, comments: comments)
  end

  def create_base64(src)
    remote_file = Down.open(src)
    remote_file.size
    base64 = Base64.strict_encode64(remote_file.read)
    remote_file.close
    'data:image/png;base64,' + base64
  end

  def fetch_photo_comments(doc)
    comments_messages = doc.css('table.bnne p')
    doc.css('table.bnne tr:nth-child(3n+2)').first(comments_messages.count).map.with_index do |tr, i|
      row = tr.children.map(&:text).push(comments_messages[i].inner_html.to_s.encode('utf-8'))
      { username: row.first, created_at: row.second, text: row.third }.to_json
    end
  end
end