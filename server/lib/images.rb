require 'mysql2'

class Images
  TABLE_DEFINITION = <<DEF
CREATE TABLE images (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(255) NOT NULL,
  `data` MEDIUMBLOB NOT NULL,
  `captured_at` datetime NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;
DEF
  INDICES = ['CREATE INDEX `index_images_on_source` ON `images` (`source`);']

  attr_reader :connection

  def initialize(connection)
    @connection = connection
  end

  def sources
    connection.query('SELECT DISTINCT source FROM images').map { |hash| hash['source'] }
  end

  def delete_before(source, id)
    e_source = connection.escape(source)
    connection.query("DELETE FROM images WHERE source = '#{e_source}' AND id < #{id}")
  end

  def latest_image(source)
    e_source = connection.escape(source)
    connection.query("SELECT * FROM images WHERE source = '#{e_source}' ORDER BY id DESC limit 1").first
  end
end
