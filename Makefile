PERL_VERSION = latest
PERL_PATH = $(abspath local/perlbrew/perls/perl-$(PERL_VERSION)/bin)

all: git-submodules perl-deps

git-submodules:
	git submodule update --init

perl-deps: carton-install config/perl/libs.txt

Makefile-setupenv: Makefile.setupenv
	make --makefile Makefile.setupenv setupenv-update \
	    SETUPENV_MIN_REVISION=20120318

Makefile.setupenv:
	wget -O $@ https://raw.github.com/wakaba/perl-setupenv/master/Makefile.setupenv

remotedev-test remotedev-reset remotedev-reset-setupenv \
config/perl/libs.txt local-perl generatepm \
perl-exec perl-version \
carton-install carton-update local-submodules: %: Makefile-setupenv
	make --makefile Makefile.setupenv $@

always:

## License: Public Domain.
