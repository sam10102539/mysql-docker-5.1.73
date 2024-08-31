FROM ubuntu:22.04

# Install necessary packages
RUN apt-get update && \
    apt-get install -y curl wget binutils locales procps build-essential wget libncurses5-dev

# Set up locale
RUN locale-gen en_US.UTF-8 &&\
    update-locale

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Download and install MySQL
RUN cd /tmp && wget http://dev.mysql.com/get/Downloads/MySQL-5.1/mysql-5.1.73.tar.gz
RUN cd /tmp && tar xzvf mysql-5.1.73.tar.gz && cd mysql-5.1.73 && \
    ./configure \
    '--prefix=/usr' \
    '--exec-prefix=/usr' \
    '--libexecdir=/usr/sbin' \
    '--datadir=/usr/share' \
    '--localstatedir=/var/lib/mysql' \
    '--includedir=/usr/include' \
    '--infodir=/usr/share/info' \
    '--mandir=/usr/share/man' \
    '--with-system-type=debian-linux-gnu' \
    '--enable-shared' \
    '--enable-static' \
    '--enable-thread-safe-client' \
    '--enable-assembler' \
    '--enable-local-infile' \
    '--with-fast-mutexes' \
    '--with-big-tables' \
    '--with-unix-socket-path=/var/run/mysqld/mysqld.sock' \
    '--with-mysqld-user=mysql' \
    '--with-libwrap' \
    '--with-readline' \
    '--with-ssl' \
    '--without-docs' \
    '--with-extra-charsets=all' \
    '--with-plugins=max' \
    '--with-embedded-server' \
    '--with-embedded-privilege-control' \
    CXXFLAGS="-std=gnu++98" && \
    make -j 8 && \
    make install

RUN rm -rf /tmp/*

# Create mysql user and group
RUN groupadd -r mysql && useradd -r -g mysql mysql

# Set up MySQL configuration
RUN mkdir -p /etc/mysql && \
    mkdir -p /var/lib/mysql && \
    mkdir -p /etc/mysql/conf.d && \
    echo -e '[mysqld_safe]\nsyslog' > /etc/mysql/conf.d/mysqld_safe_syslog.cnf && \
    chown mysql:mysql -R /var/lib/mysql && \
    mysql_install_db --user=mysql

COPY ./my.cnf /etc/mysql/my.cnf
RUN chmod 644 /etc/mysql/my.cnf

# Copy init script and make it executable
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

RUN mkdir /run/mysqld
RUN chown mysql:mysql /var/run/mysqld
RUN chmod 755 /var/run/mysqld

RUN chown -R mysql:mysql /var/lib/mysql

# Set up entrypoint
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh
WORKDIR /var/lib/mysql
# VOLUME ["/var/lib/mysql"]

USER mysql
RUN chown -R mysql:mysql /var/lib/mysql
# ENTRYPOINT ["/entrypoint.sh"]

# Expose port
EXPOSE 3306


# Set default command
# CMD ["--defaults-file=/etc/mysql/my.cnf"]
