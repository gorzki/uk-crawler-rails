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
      csv << ['id', 'forum_name', 'board_name']
      @collection.each do |key, value|
        value.each do |forum|
          csv << [forum[:id], forum[:name], key]
        end
      end
    end
  end

  def topics_and_posts
    create_csv(filename) do |csv|
      csv << @collection.first.keys
      @collection.each do |row|
        csv << row.values
      end
    end
  end

  def users
    create_csv(filename) do |csv|
      csv << @collection.first.keys.map{ |key| key.gsub(/[^\s\p{L}]/i, '').strip }
      @collection.each do |row|
        csv << row.values
      end
    end
  end


  def gallery
    create_csv(filename) do |csv|
    end
  end

  def create_csv(filename)
    CSV.open(Rails.root.join('public', 'export', filename), "wb", col_sep: ';', encoding: 'UTF-8'){ |csv| yield(csv) }
  end
end