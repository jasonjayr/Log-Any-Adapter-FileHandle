use Log::Any qw($log);

Log::Any->set_adapter('FileHandle');



$log->info("test");


