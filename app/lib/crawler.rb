class Crawler
  URL = 'http://ulricknights.pun.pl'.freeze

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
    @errors.push("Invalid credentials, cant log in on #{URL}") and return false unless user
    true
  end

  def call
    login
    return false unless successfully_logged?
    case type
    when 'users'
      link = find_link("Lista użytkowników")
      @agent.cookies
      collection = fetch_users(page_link: link)
    when 'gallery'
      link = find_link("Galeria")
      collection = fetch_gallery(link)
    when 'boards_and_forums'
      link = find_link("Index")
      collection = fetch_boards_and_forums(link)
    when 'topics_and_posts'
      link = find_link("Index")
      @page = link.click
      forums_links = @page.links.select { |link| link.href.match?('viewforum.php?') && link.text.present? }
      collection = forums_links.flat_map{ |link| fetch_topics_and_posts(page_link: link) }
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

  def fetch_href(elem)
    elem&.attributes.try(:[],'href')&.value
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
    users_arr = @page.links.select { |link| link.href.match?('profile.php?') && link.attributes.parent.name == 'td' }
    next_page = find_next_page_link
    collection.concat(users_arr.map.with_index(1) do |user_link, index|
      @page = user_link.click
      @page.parser.css('dl').reduce({}) do |acc, obj|
        titles = obj.css('dt').map(&:text)
        values = obj.css('dd').map(&:text)
        titles.count.times do |i|
          acc.merge!(titles[i] => values[i])
        end
        acc
      end
    end)
    fetch_users(collection, page_link: next_page)
  end

  def fetch_boards_and_forums(link)
    @page = link.click
    @page.parser.css('.blocktable').reduce({}) do |acc, board|
      board_title = board.css('h2').text
      forums = board.css('tbody tr').map do |row|
        elem = row.css('a').first
        id = elem&.attributes.try(:[],'href')&.value
        name = elem.text
        { id: parse_id(id), name: name }
      end
      acc.merge(board_title => forums)
    end
  end

  def fetch_topics_and_posts(collection = [], page_link:)
    return collection unless page_link
    @page = page_link.click
    next_page = find_next_page_link
    topics_links = @page.links.select { |link| link.href.match?(/viewtopic.php?|viewpoll.php?/) && !link.href.match?(/#|&/)  && link.text.present? }
    topics_links.each do |topic_link|
      collection.concat(fetch_posts(page_link: topic_link))
    end
    fetch_topics_and_posts(collection, page_link: next_page)
  end

  def fetch_posts(collection = [], page_link:)
    return collection unless page_link
    @page = page_link.click
    next_page = find_next_page_link
    collection.concat(@page.parser.css('.blockpost').map do |post|
      elem = post.css('h2 a').first
      post_id = parse_id(fetch_href(elem), regex: /\?pid=(\w+)/)
      created_at = elem.text
      href = fetch_href(post.css('.postleft a').first)
      user_id = parse_id(href)
      post_title = post.css('.postright h3').text
      post_msg = post.css('.postright .postmsg .bbtext').inner_html.encode('utf-8')
      { post_id: post_id, post_title: post_title, link: page_link.href,  parent_id: parse_id(page_link.href), created_by: user_id, created_at: created_at, post_msg: post_msg }
    end)
    fetch_posts(collection, page_link: next_page)
  end

  def fetch_gallery(collection = [], page_link:)
    return collection unless page_link
    @page = page_link.click
    next_page = find_next_page_link
    # TODO
    fetch_gallery(collection, page_link: next_page)
  end
end