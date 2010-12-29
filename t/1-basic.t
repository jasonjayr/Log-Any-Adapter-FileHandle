use Test::More;
use IO::File;
use IO::String;
use strict;
use Log::Any;

my @log_methods = Log::Any->logging_methods();
my @detection_methods = Log::Any->detection_methods();

plan tests => 
	# require/use test
	1
	# basic function tests
	+ (@log_methods + 1 + @detection_methods)
	# custom print catcher
	+ 2 
	# testing formatting
	+ 2
;

require_ok('Log::Any::Adapter::FileHandle') or die "Can't test the rest";

{ 
	my $str = IO::String->new();
	my $log = Log::Any::Adapter::FileHandle->new(category=>'test',fh=>$str);

	my $test = join("\n", map { "[$_] test" } @log_methods)."\n";
	foreach my $meth (@log_methods) { 
		eval { 
			$log->$meth("test");
		};
		if($@) { 
			fail("Log method $meth failed:$@");
		} else { 
			pass("Log method $meth ok");
		}
	}
	my $ref = $str->string_ref;
	is($$ref,$test, "Testing to in memory IO::String filehandle");

	foreach my $meth (@detection_methods) { 
		my $ret;
		eval { 
			$ret = $log->$meth;
		};
		if($@) { 
			fail("Detection method $meth failed: $@");
		} else { 
			if($ret) { 
				pass("Detection method $meth ok, and returns true");
			} else {
				fail("Detection method $meth called w/o dying, but returns false");
			}
		}
	}
} 

{ 
	package PrintCatcher1;
	use Test::More;

	sub print { 
		my ($class, $string) = @_;
		chomp $string;
		like $string, qr/^\[\w+\] (.*?)$/, "Got log message $string";	
	}
	1;

	package main;

	my $catcher = bless {}, 'PrintCatcher1';
	my $log = Log::Any::Adapter::FileHandle->new(category=>'test',fh=>$catcher);

	$log->warning("Test message 1");
	$log->info("Test Message 2");
}

{ 
	package PrintCatcher2;
	use Test::More;
	sub print { 
		my ($class, $string) = @_;
		chomp $string;
		like $string, qr/^\|\w+\| (.*?)$/, "Got custom format log message $string";	
	}
	1;

	package main;

	my $catcher = bless {}, 'PrintCatcher2';
	my $log = Log::Any::Adapter::FileHandle->new(category=>'test',format=>'|%s| %s',fh=>$catcher);

	$log->warning("Test message 1");
	$log->info("Test Message 2");
}
