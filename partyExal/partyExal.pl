package partyExal;

use strict;
use warnings;

use Plugins;
use Globals;
use Misc;

use constant {
	PLUGINNAME => 'partyExal',
	PLUGINDESC => 'exala cada membro do grupo em intervalos de tempo',
	DEFAULT_EXAL_INTERVAL => 30
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

my %times;

sub on_AI_pre {
	if (AI::isIdle || AI::is(qw(route mapRoute follow sitAuto take items_gather items_take attack move))) {
		foreach my $player (@{$playersList->getItems}) {
			if(exists $char->{party}{users}{$player->{ID}}) {
				my $interval = DEFAULT_EXAL_INTERVAL;
				$interval = $config{"partyExal" . "_interval"} if (defined $config{"partyExal" . "_interval"});
				$times{$player->{ID}}{lastExhaled} = 0 if(!exists $times{$player->{ID}}{lastExhaled});

				if(
					defined $config{"partyExal"} &&
					timeOut($times{$player->{ID}}{lastExhaled}, $interval) &&
					CheckSelfCondition("partyExal")
				) {
					my $skill = new Skill(auto => $config{"partyExal"});
					ai_skillUse2(
						$skill,
						$skill->getLevel,
						$config{"partyExal_maxCastTime"},
						$config{"partyExal_minCastTime"},
						$player,
						"partyExal",
					);

					$times{$player->{ID}}{lastExhaled} = time;

					last;
				}
			}
		}
	}
}

sub on_unload {
	Plugins::delHooks($hooks);
}

1;