package pmConsoleAdmin;

use strict;

use Globals;
use Plugins;
use Log qw(message error debug);
use Commands;

use constant {
	PLUGIN_NAME => 'pmConsoleAdmin',
	PLUGIN_DESC => 'execute pm from admin as console command'
};

Plugins::register(
	PLUGIN_NAME,
	PLUGIN_DESC,
	\&on_unload,
	undef
);

my $hooks = Plugins::addHooks(
	['start3', \&on_start3, undef],
	['ChatQueue::add', \&on_ChatQueue_add, undef]
);

sub on_ChatQueue_add {
	my $args = $_[1];
	my ($user, $msg) = ($args->{user}, $args->{msg});

	if($overallAuth{$user} == 1) {
		Commands::run($msg);
	}
}

sub on_start3 {
	Plugins::unload(PLUGIN_NAME) unless(defined $config{adminPassword} && $config{inGameAuth});
}

sub on_unload {
	Plugins::delHooks($hooks);
}

1;