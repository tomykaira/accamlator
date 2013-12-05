# deployment

## Requirements

- libmysqlclient-dev
- ruby (rbenv)
- bundler
- rbenv is always enabled https://github.com/sstephenson/rbenv/issues/350#issuecomment-14125255

## To sakura

    git clone https://github.com/tomykaira/accamlator.git
    bundle install
    bundle exec rake db:create
    bundle exec foreman start # test with foreman
    sudo /home/tomita/.rbenv/shims/bundle exec foreman export --app accamlator --user tomita upstart /etc/init
    sudo start accamlator
