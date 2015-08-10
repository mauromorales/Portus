FROM opensuse:13.2

# see update.sh for why all "apt-get install"s have to stay as one long line
RUN zypper -n --gpg-auto-import-keys refresh
RUN zypper -n --gpg-auto-import-keys update
RUN zypper -n --gpg-auto-import-keys install nodejs mariadb-client ruby2.2

ENV RAILS_VERSION 4.2.2

RUN gem install rails --version "$RAILS_VERSION"

RUN mkdir /portus
WORKDIR /portus
ADD . /portus
RUN bundle install

ENV COMPOSE=1

EXPOSE 3000
