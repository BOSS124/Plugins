package flagBuffSlave;

use strict;

use Plugins;
use Globals;
use Log qw(message debug error);
use Misc qw(checkSelfCondition checkPlayerCondition);
use Utils qw(inRange distance);
use AI;
use Actor;
use Commands;

use Time::HiRes qw(time);

use constant {
	PLUGIN_NAME => 'flagBuffSlave',
	PLUGIN_DESC => 'slave buffs every player that flags him/her',
	FLAG_EMOTICON => 51,
	DEFAULT_MAX_HEAL => 1
};

my $max_heal = DEFAULT_MAX_HEAL;

Plugins::register(
	PLUGIN_NAME,
	PLUGIN_DESC,
	\&on_unload,
	undef
);

my $hooks = Plugins::addHooks(
	['packet/emoticon', \&on_packet_emoticon, undef],
	['AI_pre', \&on_AI_pre, undef]
);

my $cmd = Commands::register(
	['set_max_heal', '', \&on_set_max_heal]
);

sub on_set_max_heal {
	$max_heal = defined($_[1]) ? $_[1] : DEFAULT_MAX_HEAL;
	message "[".PLUGIN_NAME."] max_heal set to ".$max_heal."\n";
}

sub on_AI_pre {
	if(AI::is('buffThisNewbie')) {
		my $args = AI::args();
		my $playerID = $args->{playerID};
		my $sprefix = $args->{skillprefix};
		message "Skill prefix: ".$sprefix."\n";
		my $player = $playersList->getByID($playerID);

		my %party_skill;
		$party_skill{skillObject} = Skill->new(auto => $config{$sprefix});
		$party_skill{owner} = $party_skill{skillObject}->getOwner;

		unless(defined $player && inRange(distance($party_skill{owner}{pos_to}, $player->{pos}), $config{partySkillDistance} || "0..8")) {
			AI::dequeue();
			return;
		}

		if(checkSelfCondition($sprefix)) {
			$party_skill{ID} = $party_skill{skillObject}->getHandle;
			$party_skill{lvl} = $config{$sprefix."_lvl"} || $char->getSkillLevel($party_skill{skillObject});
			$party_skill{target} = $player->{name};
			$party_skill{targetActor} = $player;
			my $pos = $player->position;
			$party_skill{x} = $pos->{x};
			$party_skill{y} = $pos->{y};
			$party_skill{targetID} = $playerID;
			$party_skill{maxCastTime} = $config{$sprefix."_maxCastTime"};
			$party_skill{minCastTime} = $config{$sprefix."_minCastTime"};
			$party_skill{isSelfSkill} = $config{$sprefix."_isSelfSkill"};
			$party_skill{prefix} = $sprefix;
			$sprefix =~ /^partySkill_(\d+)$/;
			$targetTimeout{$playerID}{$party_skill{ID}} = $1;

			if (defined $party_skill{targetID}) {
				ai_skillUse2(
					$party_skill{skillObject},
					$party_skill{lvl},
					$party_skill{maxCastTime},
					$party_skill{minCastTime},
					$party_skill{targetActor},
					$party_skill{prefix},
				);
				message "skilled\n";
			}

			AI::dequeue();
		}
	}		
}

sub on_packet_emoticon {
	my $pargs = $_[1];
	my ($playerID, $emoticonType) = (${$pargs}{ID}, ${$pargs}{type});

	if($emoticonType == FLAG_EMOTICON) {
		my @prefixes = ();

		for(my $i = 0; exists $config{"partySkill_$i"}; $i++) {
			if($config{"partySkill_$i"} eq 'AL_HEAL') {
				foreach (1..$max_heal) {
					push @prefixes, "partySkill_$i";
				}
			}
			elsif(!$config{"partySkill_$i"."_isSelfSkill"}) {
				push @prefixes, "partySkill_$i";
			}
		}

		for(my $i = $#prefixes; $i >= 0; $i--) {
			my %args;
			$args{playerID} = $playerID;
			$args{skillprefix} = $prefixes[$i];

			AI::queue('buffThisNewbie', \%args);
			message "Queued: ".$args{skillprefix}."\n";
		}
	}
}

sub on_unload {
	Plugins::delHooks($hooks);
	Commands::unregister($cmd);
}

1;