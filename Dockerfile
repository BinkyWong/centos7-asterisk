FROM centos:7

RUN yum install -y epel-release

RUN yum makecache fast

RUN yum -y groupinstall 'Development Tools'

RUN yum install -y ntpdate ngrep libedit-devel speex-devel speexdsp-devel libogg-devel libvorbis-devel alsa-lib-devel portaudio-devel libcurl-devel xmlstarlet postgresql-devel unixODBC-devel neon-devel gmime-devel lua-devel uriparser-devel libxslt-devel mysql-devel bluez-libs-devel radcli-devel freetds-devel jack-audio-connection-kit-devel net-snmp-devel iksemel-devel corosynclib-devel newt-devel popt-devel libical-devel spandsp-devel libresample-devel uw-imap-devel binutils-devel gsm-devel graphviz openldap-devel hoard python-devel openssl-devel libsrtp-devel mlocate libsrtp net-tools jansson-devel ncurses-devel ncurses-dev uuid-devel libuuid-devel libxml2-devel sqlite-devel bison subversion git-core vim wget git curl 


WORKDIR /tmp
# Get pj project
RUN git clone -b pjproject-2.4.5 --depth 1 https://github.com/asterisk/pjproject.git

# Build pj project
WORKDIR /tmp/pjproject
RUN ./configure --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-sound --disable-resample --disable-video --disable-opencore-amr 1> /dev/null
RUN make dep 1> /dev/null
RUN make 1> /dev/null
RUN make install
RUN ldconfig
RUN ldconfig -p | grep pj

ENV AUTOBUILD_UNIXTIME 123124

WORKDIR /opt

RUN wget http://downloads.asterisk.org/pub/telephony/certified-asterisk/asterisk-certified-13.21-current.tar.gz

RUN tar xvfz asterisk-certified-13.21-current.tar.gz

WORKDIR /opt/asterisk-certified-13.21-cert3

# Configure
RUN ./configure --libdir=/usr/lib64 1> /dev/null
# Remove the native build option
# from: https://wiki.asterisk.org/wiki/display/AST/Building+and+Installing+Asterisk
RUN make menuselect.makeopts
RUN menuselect/menuselect \
  --disable BUILD_NATIVE \
  --enable cdr_csv \
  --enable chan_sip \
  --enable res_snmp \
  --enable res_http_websocket \
  --enable res_hep_pjsip \
  --enable res_hep_rtcp \
  menuselect.makeopts

# Continue with a standard make.
RUN make 1> /dev/null
RUN make install 1> /dev/null
RUN make samples 1> /dev/null
WORKDIR /

# Update max number of open files.
RUN sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk

CMD asterisk -fvvvv
