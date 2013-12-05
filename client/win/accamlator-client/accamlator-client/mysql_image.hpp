#include <mysql.h>
#include <string>

class MySQLImage {
private:
  MYSQL *mysql;
  const std::string source;
  MYSQL_STMT *insert_statement;

public:
  MySQLImage(std::string hostname, std::string source);
  ~MySQLImage();

  void saveImage(std::string data) const;
};
