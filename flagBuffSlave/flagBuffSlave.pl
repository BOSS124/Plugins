package flagBuffSlave;

use strict;

use Plugins;
use Globals;
use Log qw(message debug error);
use Misc qw(checkSelfCondition checkPlayerCondition configModify saveConfigFile);
use Utils qw(inRange distance existsInList);
use AI;
use Actor;
use Commands;
use Skill;

use constant {
	PLUGIN_NAME => 'flagBuffSlave',
	PLUGIN_DESC => 'slave buffs every player that flags him/her',
	FLAG_EMOTICON => 51,
	DEFAULT_MAX_HEAL => 1,
	DEFAULT_REBUFF_INTERVAL => 60,
	DEFAULT_TIME_NO_SEE => 600,
	STATE_IDLE => 1,
	STATE_BUSY => 2
};

# Control structures
my $max_heal;
my $rebuff_interval;
my $time_no_see;
my @on_queue;
my %player_info;
my $state;
#-------------------

Plugins::register(
	PLUGIN_NAME,
	PLUGIN_DESC,
	\&on_unload,
	undef
);

my $hooks = Plugins::addHooks(
	['start3', \&on_start3, undef],
	['AI_pre', \&on_AI_pre, undef],
	['packet/emoticon', \&on_packet_emoticon, undef]
);

my $cmd = Commands::register(
	['set_max_heal', 'change set_max_heal value', \&on_set_max_heal],
	['set_rebuff_interval', 'change rebuff interval value', \&on_set_rebuff_interval],
	['set_time_no_see', 'change time_no_see value', \&on_set_time_no_see]
);

sub on_AI_pre {
	clear_player_info();

	foreach my $player (@{$playersList->getItems}) {
		if(exists $player_info{$player->{ID}} && !is_on_queue($player->{ID})) {
			if((time - $player_info{$player->{ID}}{last_buffed}) >= $rebuff_interval) {
				push @on_queue, $player->{ID};
			}
		}
	}

	if(@on_queue > 0 && $state == STATE_IDLE) {
		queue_player(shift @on_queue);
		$state = STATE_BUSY;
	}

	if(AI::is('buffThisNewbie') && main::timeOut(time, $timeout{ai_skill_use}{timeout})) {
		my $args = AI::args;
		my $playerID = $args->{playerID};
		my $player = $playersList->getByID($playerID);

		unless (scalar @{$args->{skills}} > 0) {
			$player_info{$playerID}{last_buffed} = time;
			AI::dequeue;
			$state = STATE_IDLE;
			return;
		}

		my $skillco = scalar @{$args->{skills}};
		message "$skillco";

		my $sprefix = ${$args->{skills}}[0];
		shift @{$args->{skills}} if($prefix eq "");
		return;

		my %party_skill;
		$party_skill{skillObject} = Skill->new(auto => $config{$sprefix});
		$party_skill{owner} = $party_skill{skillObject}->getOwner;

		return unless(defined $player);

		unless(inRange(distance($party_skill{owner}{pos_to}, $player->{pos}), $config{partySkillDistance} || "0..8")) {
			AI::dequeue;
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
			$party_skill{prefix} = $sprefix;
			message "SKILL: $party_skill{prefix}";
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
			}
			shift @{$args->{skills}};
		}
	}		
}

sub on_start3 {
	if(defined $config{PLUGIN_NAME.'_max_heal'}) {
		$max_heal = $config{PLUGIN_NAME.'_max_heal'};
		message "[".PLUGIN_NAME."] Max Heal set to: ".$max_heal."\n";
	} else {
		$max_heal = DEFAULT_MAX_HEAL;
		message "[".PLUGIN_NAME."] Max Heal set to: ".$max_heal."\n";
	}

	if(defined $config{PLUGIN_NAME.'_rebuff_interval'}) {
		$rebuff_interval = $config{PLUGIN_NAME.'_rebuff_interval'};
		message "[".PLUGIN_NAME."] Rebuff Interval set to: ".$rebuff_interval." seconds\n";
	} else {
		$rebuff_interval = DEFAULT_REBUFF_INTERVAL;
		message "[".PLUGIN_NAME."] Rebuff Interval set to: ".$rebuff_interval." seconds\n";
	}

	if(defined $config{PLUGIN_NAME.'_time_no_see'}) {
		$time_no_see = $config{PLUGIN_NAME.'_time_no_see'};
		message "[".PLUGIN_NAME."] Time No See set to: ".$time_no_see." seconds\n";
	} else {
		$time_no_see = DEFAULT_TIME_NO_SEE;
		message "[".PLUGIN_NAME."] Time No See set to: ".$time_no_see." seconds\n";
	}

	$state = STATE_IDLE;
}

sub on_packet_emoticon {
	my $pargs = $_[1];
	my ($playerID, $emoticonType) = (${$pargs}{ID}, ${$pargs}{type});

	if($emoticonType == FLAG_EMOTICON) {
		$player_info{$playerID}{last_buffed} = 0 unless(exists $player_info{$playerID});
	}
}

sub on_set_max_heal {
	if (defined $_[1]) {
		$max_heal = $_[1];
		configModify(PLUGIN_NAME.'_max_heal', $_[1]);
		saveConfigFile();
		message "[".PLUGIN_NAME."] Max Heal set to: ".$max_heal."\n";
	}
	else {
		message "[".PLUGIN_NAME."] Command failed\n";
	}
}

sub on_set_rebuff_interval {
	if (defined $_[1]) {
		$rebuff_interval = $_[1];
		configModify(PLUGIN_NAME.'_rebuff_interval', $_[1]);
		saveConfigFile();
		message "[".PLUGIN_NAME."] Rebuff Interval set to: ".$rebuff_interval." seconds\n";
	}
	else {
		message "[".PLUGIN_NAME."] Command failed\n";
	}
}

sub set_time_no_see {
	if (defined $_[1]) {
		$time_no_see = $_[1];
		configModify(PLUGIN_NAME.'_time_no_see', $_[1]);
		saveConfigFile();
		message "[".PLUGIN_NAME."] Time No See set to: ".$time_no_see." seconds\n";
	}
	else {
		message "[".PLUGIN_NAME."] Command failed\n";
	}
}

sub clear_player_info {
	foreach my $key (keys %player_info) {
		if($player_info{$key}{last_buffed} > 0 && (time - $player_info{$key}{last_buffed}) >= $time_no_see) {
			delete $player_info{$key};
		}
	}
}

sub queue_player {
	return unless defined $_[0];

	my %args;

	$args{playerID} = $_[0];
	$args{skills} = [];

	for(my $i = 0; exists $config{"partySkill_$i"}; $i++) {
		if($config{"partySkill_$i"} eq 'AL_HEAL') {
			foreach (1..$max_heal) {
				push @{$args{skills}}, "partySkill_$i";
			}
		}
		elsif(!$config{"partySkill_$i"."_isSelfSkill"} &&) {
			push @{$args{skills}}, "partySkill_$i";
		}
	}

	AI::queue('buffThisNewbie', \%args);
}

sub is_on_queue {
	foreach my $id (@on_queue) {
		return 1 if($id eq $_[0]);
	}
	return 0;
}

sub on_unload {
	undef $max_heal;
	undef $rebuff_interval;
	undef $time_no_see;
	undef @on_queue;
	undef %player_info;
	undef $state;
	Plugins::delHooks($hooks);
	Commands::unregister($cmd);
}

1;