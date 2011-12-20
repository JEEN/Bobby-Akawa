use inc::Module::Install;

name 'Bobby';
all_from 'lib/Bobby.pm';

requires 'Tatsumaki';
requires 'Moose';
requires 'Config::ZOMG';
requires 'Furl';
requires 'JSON::XS';
requires 'LWP::UserAgent';
auto_install;
WriteAll;
