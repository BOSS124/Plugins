package groundSkills;

use strict;

use Plugins;
use Globals;
use AI;
use Misc qw(checkSelfCondition);
use Skill;
use Task;
use Task::ErrorReport;

use constant {
	PLUGINNAME => 'groundSkills',
	PLUGINDESC => 'suporte para usar skills em posições definidas do terreno',
};

Plugins::register(
	PLUGINNAME,
	PLUGINDESC,
	\&onUnload,
	undef
);

my $hooks = Plugins::addHooks(
	['AI_pre', \&on_AI_pre, undef]
);

sub on_AI_pre {
	if (AI::isIdle && !AI::inQueue(qw/skill_use/)) {
		for (my $i = 0; exists $config{"groundSkill_$i"}; $i++) {
			if (
				checkSelfCondition("groundSkill_$i") &&
				defined $config{"groundSkill_$i"."_x"} &&
				defined $config{"groundSkill_$i"."_y"}
			) {

				my ($x, $y) = ($config{"groundSkill_$i" . "_x"} , $config{"groundSkill_$i" . "_y"});

				my $skill;

				if(defined $config{"groundSkill_$i"."_lvl"}) {
					$skill = new Skill(auto => $config{"groundSkill_$i"}, level => $config{"groundSkill_$i"."_lvl"});
				} else {
					$skill = new Skill(auto => $config{"groundSkill_$i"});
				}

				ai_skillUse(
					$skill->getHandle,
					$skill->getLevel,
					$config{"groundSkill_$i" . "_maxCastTime"},
					$config{"groundSkill_$i" . "_minCastTime"},
					$x,
					$y,
					undef,
					undef,
					undef,
					"groundSkill_$i"
				);

				$ai_v{"groundSkill_$i" . "_time"} = time;
			}
		}
	}
}

sub onUnload {
	Plugins::delHooks($hooks);
}

1;