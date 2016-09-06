use v5.16;
use warnings;
use AnyEvent;
use AnyEvent::IO qw(:flags);
use IPC::Run qw( start ); 
use Time::HiRes qw( gettimeofday tv_interval );

# Start a timer that, every 0.5 seconds, sleeps for 1 second, then prints "timer":
my $w1 = AnyEvent->timer(
    after => 10,
    cb => sub {
        say "failed after 10s"; 
	exit(1);
    },
);

my $w2 = AnyEvent->timer(
    after => 0,
    interval => 0.5,
    cb => sub {
	my $t0 = [gettimeofday()];
	# Simulated blocking operation. If this is removed, everything works.
	while (tv_interval($t0) < 1) {} # Busy wait so as not to confound test results with the fact that sleep gets interrupted by SIGCHLD.
    },
);

# Fork off a pid that waits for 2 seconds and then exits:
my $pid = start([qw( sleep 2 )])->{KIDS}->[0]->{PID};

# Print "child" when the child process exits, then shut down:
my $child = AnyEvent->child(
    pid => $pid,
    cb => sub {
        say "success";
	exit();
    },
);

AnyEvent->condvar->recv;
