==> Summary
🍺  /usr/local/Cellar/openssl@3/3.6.1: 7,615 files, 38.0MB, built in 11 minutes 49 seconds
==> Installing mas dependency: readline
==> Patching
==> Applying readline83-001
==> Applying readline83-002
==> Applying readline83-003
==> ./configure --with-curses
==> make install SHLIB_LIBS=-lcurses
🍺  /usr/local/Cellar/readline/8.3.3: 56 files, 2.6MB, built in 1 minute 26 seconds
==> Installing mas dependency: sqlite
==> ./configure --enable-readline --disable-editline --enable-session --with-readline-cflags=-I/usr/
==> make install
🍺  /usr/local/Cellar/sqlite/3.51.2_1: 13 files, 5.2MB, built in 2 minutes 7 seconds
==> Installing mas dependency: xz
==> ./configure --disable-silent-rules --disable-nls
==> make check
==> make install
🍺  /usr/local/Cellar/xz/5.8.2: 96 files, 2.6MB, built in 2 minutes 19 seconds
==> Installing mas dependency: lz4
==> Pouring lz4--1.10.0.monterey.bottle.1.tar.gz
🍺  /usr/local/Cellar/lz4/1.10.0: 24 files, 780.6KB
==> Installing mas dependency: cmake
==> Patching
==> Applying 6347854fa279cda0682c72dffbb402a0ce29ba51.patch
==> ./bootstrap --prefix=/usr/local/Cellar/cmake/4.2.3 --no-system-libs --parallel=4 --datadir=/shar

