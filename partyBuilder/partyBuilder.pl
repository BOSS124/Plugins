package partyBuilder;

use strict;
use warnings;

use Plugins;
use Globals;
use Log;
use Misc;
use AI;
use Network::Send;


use constant {
	PLUGINNAME => 'partyBuilder',
	PLUGINDESC => 'monta pt e organiza automaticamente',
	STATE_IDLE => 0,
	STATE_CHAT_OPENED =>
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
	for (my $i = 0; exists $config{"partyBuilder_$i"}; $i++) {
		my ($minLvl, $maxLvl) = ($config{"partyBuilder_$i"."_minLvl"}, $config{"partyBuilder_$i"."_maxLvl"});
		if($config{"lockMap"} ne $config{"partyBuilder_$i"} && $char->{lv} >= $minLvl && $char->{lv} <= $maxLvl ) {
			
			configModify("lockMap", $config{"partyBuilder_$i"});
			configModify("lockMap_x", $config{"partyBuilder_$i"."_posx"});
			configModify("lockMap_y", $config{"partyBuilder_$i"."_posy"});
			last;
		}
	}

	if(AI::isIdle) {
		
	}
}

sub on_unload {
	Plugins::delHooks($hooks);
}

1;