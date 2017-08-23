# dcAutoQuit plugin for OpenKore by dallok
#
# This software is open source, licensed under the GNU General Public
# License, version 2.

package dcAutoQuit;

use strict;

use Plugins;
use Log qw(message debug);
use Time::HiRes qw(time tv_interval);
use Globals qw(%config);
use Misc qw(quit);
use Commands;

use constant {
	PLUGIN_NAME => "dcAutoQuit",
	DEFAULT_DC_COUNT => 2,
	DEFAULT_DC_INTERVAL => 60
};

Plugins::register(PLUGIN_NAME, 'verifica dcs dentro de um intervalo de tempo', \&onUnload);

my @dc_time = ();

my $hooks = Plugins::addHooks(
	['start3', \&checkConfig, undef],
	['disconnected', \&disconnect, undef]
);

my $dc_count = Commands::register(
	['dc_count', 'informa o usuário quantas vezes ele foi desconectado durante a execução do Openkore', \&on_dc_count]
);

sub disconnect {
	my $dcs = $config{dcAutoQuit_count};
	push (@dc_time, time());

	if(scalar (@dc_time) >= $config{dcAutoQuit_count}) {
		my $interval = $dc_time[$#dc_time] - $dc_time[scalar (@dc_time) - $dcs];
		if($interval <= $config{dcAutoQuit_interval}) {
			message "[".PLUGIN_NAME."] Voce foi desconectado " . $dcs . " vezes num intervalo de " . $interval . " segundos\n";
			message "[".PLUGIN_NAME."] Fechando Openkore...\n";
			Misc::quit();
		}
	}
}

sub onUnload {
	Plugins::delHooks($hooks);
	Commands::unregister($dc_count);
	undef $hooks;
	undef @dc_time;
	message "[".PLUGIN_NAME."] Plugin unloaded\n";
}

sub checkConfig {
	if(!exists($config{dcAutoQuit_enabled}) || $config{dcAutoQuit_enabled} eq "false") {
		debug "[".PLUGIN_NAME."] dcAutoQuit_enabled is set to false. Unloading plugin\n";
		Plugins::unload(PLUGIN_NAME);
	} else {
		$config{dcAutoQuit_count} = DEFAULT_DC_COUNT if(!exists($config{dcAutoQuit_count}));
		$config{dcAutoQuit_interval} = DEFAULT_DC_INTERVAL if(!exists($config{dcAutoQuit_interval}));
	}
	debug "[".PLUGIN_NAME."] dcAutoQuit_count set to ".$config{dcAutoQuit_count}."\n";
	debug "[".PLUGIN_NAME."] dcAutoQuit_interval set to".$config{dcAutoQuit_interval}."\n";
}

sub on_dc_count {
	my $dc_count = scalar(@dc_time);
	message "[".PLUGIN_NAME."] Voce foi desconectado ".$dc_count." vezes\n";
}

1;