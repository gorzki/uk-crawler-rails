require 'csv'

class Generator
  ACTIONS = %w(boards_and_forums topics_and_posts users gallery).freeze

  def initialize(collection:, type:)
    @collection = collection
    @type = type.to_s
  end

  def filename
    @filename ||= %Q(#{@type}_#{DateTime.current.strftime("%Q")}.csv)
  end
  
  def call
    return false unless valid?
    send(@type)
    log_export
    true
  end

  private

  def valid?
    @type.presence_in(ACTIONS) && @collection.present?
  end

  def log_export
    Export.create(filename: filename, path: 'export/' + filename)
  end

  def boards_and_forums
    create_csv(filename) do |csv|
      csv << ['board_title', 'forum_id', 'forum_title']
      @collection.each do |board_title, forums|
        forums.each do |forum|
          csv << [board_title, *forum.values]
        end
      end
    end
  end

  def topics_and_posts
    create_csv(filename) do |csv|
      csv << ['forum_id', *Crawler::POST_KEYS]
      @collection.each do |forum_id, posts|
        posts.each do |post|
          csv << [forum_id, *post.values]
        end
      end
    end
  end

  def users
    create_csv(filename) do |csv|
      csv << Crawler::USER_KEYS
      @collection.each do |row|
        csv << row.values
      end
    end
  end


  def gallery
    create_csv(filename) do |csv|
      csv << ['gallery_id', 'gallery_title', *Crawler::PHOTO_KEYS]
      @collection.each do |gallery, photos|
        photos.each do |row|
          csv << [gallery.id, gallery.title, *row.values]
        end
      end
    end
  end

  def create_csv(filename)
    CSV.open(Rails.root.join('public', 'export', filename), "wb", col_sep: ';', encoding: 'UTF-8'){ |csv| yield(csv) }
  end
end