package dcNotPartyPlayer;

use strict;
use warnings;

use Plugins;
use Globals;

use constant {
	PLUGINNAME => 'dcNotPartyPlayer',
	PLUGINDESC => 'auehuaheuha'
};

Plugins::register(
	PLUGINNAME,
	PLUGINDESC,
	\&on_unload,
	undef
);

my $hooks = Plugins::addHooks(
	['AI_pre', \&on_AI_pre, undef]
);

sub on_AI_pre {
	foreach my $player (@{$playersList->getItems}) {
		if($net->getState() == Network::IN_GAME) {
			Commands::run("relog 900") unless(exists $char->{party}{users}{$player->{ID}});
		}
	}
}

sub on_unload {
	Plugins::delHooks($hooks);
}

1;