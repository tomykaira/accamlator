#include "mysql_image.hpp"
#include <cstring>

MySQLImage::MySQLImage(std::string hostname, std::string source) : source(source)
{
  mysql = mysql_init(NULL);
  if (mysql == NULL) {
    throw "'mysql_init()' failed. Insufficient memory.";
  }

  if (mysql_real_connect(mysql, hostname.c_str(), "accam_client", NULL, "accamlator", 0, NULL, 0) == NULL) {
    throw "'mysql_real_connect()' failed. " + std::string(mysql_error(mysql));
  }

  MYSQL_STMT* stmt = mysql_stmt_init(mysql);
  if (!stmt)
    throw "'mysql_stmt_init()' failed. " +  std::string(mysql_error(mysql));

  std::string query = "INSERT INTO images (source, data, captured_at) VALUES (?, ?, CURRENT_TIMESTAMP())";
  if (mysql_stmt_prepare(stmt, query.c_str(), query.size())) {
    throw "'mysql_stmt_prepare()' failed. " +  std::string(mysql_error(mysql));
  }

  insert_statement = stmt;
}

MySQLImage::~MySQLImage()
{
  mysql_close(mysql);
}

void MySQLImage::saveImage(std::string data) const
{
  MYSQL_BIND bind[2];
  memset(bind, 0, sizeof(bind));
  bind[0].buffer_type = MYSQL_TYPE_STRING;
  bind[0].buffer_length = source.size();
  bind[0].buffer = (void *)source.c_str();

  bind[1].buffer_type = MYSQL_TYPE_BLOB;
  bind[1].buffer_length = data.size();
  bind[1].buffer = (void *)data.c_str();

  if (mysql_stmt_bind_param(insert_statement, bind)) {
    throw "'mysql_stmt_bind_param()' failed. " +  std::string(mysql_stmt_error(insert_statement));
  }

  if (mysql_stmt_execute(insert_statement)) {
    throw "'mysql_stmt_execute()' failed. " +  std::string(mysql_stmt_error(insert_statement));
  }
}
