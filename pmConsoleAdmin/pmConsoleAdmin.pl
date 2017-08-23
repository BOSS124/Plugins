package pmConsoleAdmin;

use strict;

use Globals;
use Plugins;
use Log qw(message error debug);
use Commands;
use Misc qw(sendMessage);

use constant {
	PLUGIN_NAME => 'pmConsoleAdmin',
	PLUGIN_DESC => 'execute pm from admin as console command or custom command'
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
		if($msg =~ /^(\w+)\s+(.+)$/) {
			my $cmd = $1;
			my @params = split /,(\s*)/, $2;

			if($cmd eq 'iteminfo') {
				foreach my $itemname (@params) {
					foreach my $item (@{$char->inventory}) {
						if($item->{name} eq $itemname) {
							sendMessage($messageSender, "pm", "$item->{binID} / $item->{name} / $item->{amount}", $user);
						}
					}
				}
				return;
			}
		}

		if($msg =~ /^(\w+)$/) {
			my $cmd = $1;

			if($cmd eq 'invinfo') {
				foreach my $item (@{$char->inventory}) {
					sendMessage($messageSender, "pm", "$item->{binID} / $item->{name} / $item->{amount}", $user);
				}
				return;
			}
		}

		Commands::run($msg);
		sendMessage($messageSender, "pm", "O comando foi executado no console", $user);
	}
}

sub on_start3 {
	Plugins::unload(PLUGIN_NAME) unless(defined $config{adminPassword} && $config{inGameAuth});
}

sub on_unload {
	Plugins::delHooks($hooks);
}

1;